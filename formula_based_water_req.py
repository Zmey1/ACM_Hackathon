import math
import csv
import os
import requests
from datetime import datetime, timedelta

# ================== LOAD CSV DATA ==================
def load_csv_data(file_path):
    """Load CSV data into a list of dictionaries"""
    with open(file_path, 'r') as file:
        reader = csv.DictReader(file)
        return list(reader)

def load_soil_properties(csv_path):
    """Load soil properties from CSV"""
    soil_data = load_csv_data(csv_path)
    soil_properties = {}
    
    for row in soil_data:
        soil_type = row['soil_type']
        soil_properties[soil_type] = {
            'water_holding_capacity': float(row['water_holding_capacity']),
            'field_capacity': float(row['field_capacity']),
            'wilting_point': float(row['wilting_point']),
            'infiltration_rate': float(row['infiltration_rate']),
            'bulk_density': float(row['bulk_density']),
            'texture': {
                'sand': int(row['sand']), 
                'silt': int(row['silt']), 
                'clay': int(row['clay'])
            }
        }
    
    return soil_properties

def load_crop_properties(csv_path):
    """Load crop properties from CSV"""
    crop_data = load_csv_data(csv_path)
    crop_properties = {}
    
    for row in crop_data:
        crop_name = row['crop']
        crop_properties[crop_name] = {
            'kc_values': {
                'initial': float(row['kc_initial']),
                'development': float(row['kc_development']),
                'mid_season': float(row['kc_mid_season']),
                'late_season': float(row['kc_late_season'])
            },
            'growth_stages': {
                'initial': int(row['stage_initial_days']),
                'development': int(row['stage_development_days']),
                'mid_season': int(row['stage_mid_season_days']),
                'late_season': int(row['stage_late_season_days'])
            },
            'root_depth': {
                'initial': float(row['root_initial']),
                'development': float(row['root_development']),
                'mid_season': float(row['root_mid_season']),
                'late_season': float(row['root_late_season'])
            },
            'critical_depletion': {
                'initial': float(row['depletion_initial']),
                'development': float(row['depletion_development']),
                'mid_season': float(row['depletion_mid_season']),
                'late_season': float(row['depletion_late_season'])
            },
            'water_sensitivity': float(row['water_sensitivity']),
            'typical_yield': float(row['typical_yield']),
            'growing_seasons': row['growing_seasons'].split(',')
        }
    
    return crop_properties

def load_location_constants(csv_path):
    """Load location constants from CSV"""
    constants_data = load_csv_data(csv_path)
    constants = {}
    
    for row in constants_data:
        param = row['parameter']
        value = row['value']
        
        # Handle special cases
        if param in ['monsoon_months', 'dry_months', 'hottest_months', 'coolest_months']:
            constants[param] = [int(x) for x in value.strip('"').split(',')]
        elif param in ['latitude', 'longitude', 'elevation', 'reference_et', 
                    'annual_rainfall', 'annual_min_temp', 'annual_max_temp']:
            constants[param] = float(value)
        else:
            constants[param] = value
    
    # Structure similar to original code
    return {
        'latitude': constants.get('latitude', 0),
        'longitude': constants.get('longitude', 0),
        'elevation': constants.get('elevation', 0),
        'reference_et': constants.get('reference_et', 5.0),
        'rainfall_pattern': {
            'annual': constants.get('annual_rainfall', 0),
            'monsoon_months': constants.get('monsoon_months', []),
            'dry_months': constants.get('dry_months', [])
        },
        'temperature': {
            'annual_min': constants.get('annual_min_temp', 0),
            'annual_max': constants.get('annual_max_temp', 0),
            'hottest_months': constants.get('hottest_months', []),
            'coolest_months': constants.get('coolest_months', [])
        }
    }

# ================== FARMER-FRIENDLY GUIDANCE ==================
def get_water_depth_guidance(crop_type, growth_stage):
    """
    Returns farmer-friendly description of water depth based on crop and growth stage
    """
    guidance = {
        "Rice": {
            "initial": "Keep soil moist but not flooded",
            "development": "Maintain water level at 1-2 cm (about one finger joint)",
            "mid_season": "Maintain water level at 5-7 cm (up to your middle finger joint)",
            "late_season": "Reduce water to 2-3 cm depth as the crop approaches maturity"
        },
        "Sugarcane": {
            "initial": "Keep soil moist to support germination",
            "development": "Water to a depth of 3-4 cm when soil appears dry",
            "mid_season": "Ensure soil is moist to a depth of your finger length",
            "late_season": "Reduce watering as the cane matures and sweetens"
        },
        "Groundnut": {
            "initial": "Keep soil just moist to aid germination",
            "development": "Water to moisten soil to a depth of 5 cm (first finger joint)",
            "mid_season": "Ensure soil is moist but not waterlogged during flowering",
            "late_season": "Reduce watering as pods mature (allows pods to develop fully)"
        },
        "Cotton": {
            "initial": "Maintain soil moisture for seedling establishment",
            "development": "Water to a depth of your first finger joint when soil surface dries",
            "mid_season": "Ensure consistent moisture during boll formation",
            "late_season": "Reduce irrigation as bolls open to prevent rotting"
        },
        "Banana": {
            "initial": "Keep soil continuously moist but not waterlogged",
            "development": "Ensure soil is moist to the depth of your hand",
            "mid_season": "Maintain consistent moisture during fruit development",
            "late_season": "Continue regular watering until harvesting"
        },
        # Default guidance for other crops
        "default": {
            "initial": "Keep soil moist to support germination",
            "development": "Water to a depth of your first finger joint",
            "mid_season": "Ensure soil is moist to the depth of your finger",
            "late_season": "Reduce watering as the crop approaches maturity"
        }
    }
    
    # Get specific crop guidance or use default if crop not found
    crop_guidance = guidance.get(crop_type, guidance["default"])
    return crop_guidance.get(growth_stage, "Water as needed based on soil moisture")

def determine_current_growth_stage(crop_properties, crop_name, days_since_planting):
    """
    Determine the current growth stage based on days since planting
    """
    try:
        crop = crop_properties[crop_name]
        stages = list(crop['growth_stages'].items())
        
        cumulative_days = 0
        for stage, duration in stages:
            cumulative_days += duration
            if days_since_planting < cumulative_days:
                return stage
        
        # If beyond all stages, return late_season
        return "late_season"
    except:
        # Default to initial if there's any error
        return "initial"

# ================== BACKEND API CONNECTION ==================
def get_latest_prediction_data(base_url="https://ba7f-103-238-230-194.ngrok-free.app"):
    """Fetch latest prediction data from the backend API"""
    endpoint = f"{base_url}/api/crop/latest-prediction"
    
    try:
        print(f"Fetching data from API: {endpoint}")
        response = requests.get(endpoint)
        if response.status_code == 200:
            data = response.json()
            print(f"Successfully fetched data from API: {endpoint}")
            print(f"API response: {data}")
            return data
        else:
            print(f"Error fetching prediction data: {response.status_code}")
            print(f"Response: {response.text}")
            return None
    except Exception as e:
        print(f"Exception when fetching prediction data: {e}")
        return None

def format_prediction_data_for_calculations(prediction_data):
    """Format the prediction data for water requirement calculations"""
    if not prediction_data:
        return None, None, None, None, None
    
    print(f"Formatting prediction data: {prediction_data}")
    
    # Extract location data
    location = {
        'latitude': prediction_data.get('latitude', 9.2088),
        'longitude': prediction_data.get('longitude', 77.2561),
        'elevation': prediction_data.get('elevation', 150)
    }
    
    # Extract weather data
    weather_data = [{
        'date': datetime.now().strftime("%Y-%m-%d"),
        'temp_min': prediction_data.get('min_temp', 22),
        'temp_max': prediction_data.get('max_temp', 36),
        'humidity': prediction_data.get('avg_relative_humidity', 60),
        'wind_speed': prediction_data.get('avg_wind_speed', 2.0),
        'rainfall': prediction_data.get('total_rainfall', 0)
    }]
    
    # Extract crop and soil information
    crop_type = prediction_data.get('crop_type')
    soil_type = prediction_data.get('soil_type')
    
    # Process plantation date (it comes in ISO format)
    plantation_date = prediction_data.get('plantation_date')
    if plantation_date:
        # Convert from ISO format to YYYY-MM-DD
        try:
            date_obj = datetime.fromisoformat(plantation_date.replace('Z', '+00:00'))
            plantation_date = date_obj.strftime("%Y-%m-%d")
        except:
            plantation_date = datetime.now().strftime("%Y-%m-%d")
    else:
        plantation_date = datetime.now().strftime("%Y-%m-%d")
    
    print(f"Formatted data: location={location}, crop={crop_type}, soil={soil_type}, date={plantation_date}")
    
    return location, weather_data, crop_type, soil_type, plantation_date

# ================== CALCULATION FUNCTIONS ==================
def calculate_eto(tmin, tmax, elevation, lat, doy, wind_speed=2.0, rh_min=45, rh_max=75):
    """FAO Penman-Monteith equation implementation"""
    lat_rad = math.radians(lat)
    tmean = (tmax + tmin) / 2

    # Saturation vapor pressure
    es_tmin = 0.6108 * math.exp(17.27 * tmin / (tmin + 237.3))
    es_tmax = 0.6108 * math.exp(17.27 * tmax / (tmax + 237.3))
    es = (es_tmin + es_tmax) / 2

    # Actual vapor pressure
    ea = (es_tmin * (rh_max/100) + es_tmax * (rh_min/100)) / 2

    # Atmospheric parameters
    delta = 4098 * es / ((tmean + 237.3)**2)
    P = 101.3 * ((293 - 0.0065 * elevation)/293)**5.26
    gamma = 0.665e-3 * P

    # Solar calculations
    dr = 1 + 0.033 * math.cos(2 * math.pi * doy / 365)
    delta_rad = 0.409 * math.sin(2 * math.pi * doy / 365 - 1.39)
    ws = math.acos(-math.tan(lat_rad) * math.tan(delta_rad))

    # Radiation components
    Ra = (24*60/math.pi) * 0.0820 * dr * (
        ws * math.sin(lat_rad) * math.sin(delta_rad) +
        math.cos(lat_rad) * math.cos(delta_rad) * math.sin(ws)
    )
    Rso = (0.75 + 2e-5 * elevation) * Ra
    Rs = Ra * 0.5  # Estimated solar radiation

    # Net radiation
    Rns = (1 - 0.23) * Rs
    Rnl = 4.903e-9 * ((tmax + 273.16)**4 + (tmin + 273.16)**4)/2 * (0.34 - 0.14 * math.sqrt(ea)) * (1.35 * Rs/Rso - 0.35)
    Rn = Rns - Rnl

    # Final ETo calculation
    numerator = 0.408 * delta * Rn + gamma * (900/(tmean + 273)) * wind_speed * (es - ea)
    denominator = delta + gamma * (1 + 0.34 * wind_speed)
    eto = numerator / denominator

    return max(eto, 0)

def get_growth_stage(crop, day):
    """Determine current growth stage for given day"""
    stages = list(crop['growth_stages'].items())
    cumulative = 0
    for stage, duration in stages:
        cumulative += duration
        if day < cumulative:
            return stage
    return stages[-1][0]

def calculate_crop_water(crop_name, soil_type, planting_date, weather_data=None, location=None):
    """Main calculation function for crop water requirements in liters per hectare"""
    print(f"Starting water calculation for {crop_name} in {soil_type} soil, planted on {planting_date}")
    
    # Load data from CSV files
    try:
        soil_properties = load_soil_properties('soil_properties.csv')
        print(f"Loaded soil properties for: {list(soil_properties.keys())}")
    except Exception as e:
        print(f"Error loading soil properties: {e}")
        return None
        
    try:
        crop_properties = load_crop_properties('crop_properties.csv')
        print(f"Loaded crop properties for: {list(crop_properties.keys())}")
    except Exception as e:
        print(f"Error loading crop properties: {e}")
        return None
    
    # Use provided location or default to Krishnan Kovil region
    if not location:
        location = {
            'latitude': 9.2088,
            'longitude': 77.2561,
            'elevation': 150
        }
    
    # Default temperature and rainfall patterns for Krishnan Kovil
    temperature_defaults = {
        'annual_min': 22,
        'annual_max': 36,
        'hottest_months': [4, 5],
        'coolest_months': [11, 12]
    }
    
    rainfall_pattern = {
        'monsoon_months': [9, 10, 11, 12],
        'dry_months': [1, 2, 3, 4, 5]
    }
    
    # Get crop and soil data
    try:
        crop = crop_properties[crop_name]
    except KeyError:
        print(f"Warning: Crop '{crop_name}' not found in database. Using Rice as default.")
        crop_name = "Rice" 
        try:
            crop = crop_properties["Rice"]  # Default to rice if crop not found
        except KeyError:
            print("Error: Cannot find Rice in crop properties!")
            return None
    
    try:
        soil = soil_properties[soil_type]
    except KeyError:
        print(f"Warning: Soil type '{soil_type}' not found in database. Using Red Soil as default.")
        soil_type = "Red Soil"
        try:
            soil = soil_properties["Red Soil"]  # Default to red soil if soil type not found
        except KeyError:
            print("Error: Cannot find Red Soil in soil properties!")
            return None

    try:
        current_date = datetime.strptime(planting_date, "%Y-%m-%d")
        total_days = sum(crop['growth_stages'].values())
        print(f"Calculating for {total_days} days from {planting_date}")

        # Initialize soil moisture storage (mm)
        root_depth = crop['root_depth']['initial']
        available_water_max = (soil['field_capacity'] - soil['wilting_point'])/100 * root_depth*1000
        current_storage = available_water_max  # Start at field capacity

        irrigation_schedule = []
        total_water = 0

        for day in range(total_days):
            # Update growth parameters
            stage = get_growth_stage(crop, day)
            kc = crop['kc_values'][stage]
            root_depth = crop['root_depth'][stage]
            critical_depletion = crop['critical_depletion'][stage]

            # Recalculate max available water for current root depth
            available_water_max = (soil['field_capacity'] - soil['wilting_point'])/100 * root_depth*1000

            # Get weather data for this day
            # If available in forecast data, use it; otherwise, use default values
            if weather_data and day < len(weather_data):
                day_weather = weather_data[day]
                tmin = day_weather.get('temp_min', temperature_defaults['annual_min'])
                tmax = day_weather.get('temp_max', temperature_defaults['annual_max'])
                wind_speed = day_weather.get('wind_speed', 2.0)
                humidity = day_weather.get('humidity', 60)
                # Estimate relative humidity min/max from average humidity
                rh_min = max(humidity - 15, 30)
                rh_max = min(humidity + 15, 90)
            else:
                # Default to temperature defaults
                tmin = temperature_defaults['annual_min']
                tmax = temperature_defaults['annual_max']
                wind_speed = 2.0
                rh_min = 45
                rh_max = 75

            # Calculate ET components
            doy = current_date.timetuple().tm_yday
            eto = calculate_eto(
                tmin=tmin,
                tmax=tmax,
                elevation=location['elevation'],
                lat=location['latitude'],
                doy=doy,
                wind_speed=wind_speed,
                rh_min=rh_min,
                rh_max=rh_max
            )
            etc = eto * kc

            # Update soil moisture
            current_storage -= etc

            # Calculate depletion percentage
            depletion = 1 - (current_storage / available_water_max)

            # Check irrigation need
            if depletion > critical_depletion:
                irrigation_needed = available_water_max - current_storage
                irrigation_schedule.append({
                    'day_num': day+1,
                    'date': current_date.strftime("%Y-%m-%d"),
                    'amount_mm': round(irrigation_needed, 1),
                    'amount_liters_per_ha': round(irrigation_needed * 10000, 0),  # Convert mm to L/ha
                    'stage': stage
                })
                # Reset soil moisture after irrigation
                current_storage = available_water_max

            total_water += etc
            current_date += timedelta(days=1)

        # Calculate water in different units
        total_water_mm = round(total_water, 1)
        total_water_liters_per_ha = round(total_water * 10000, 0)  # 1 mm over 1 ha = 10,000 liters
        
        # Convert to liters per acre
        hectare_to_acre = 2.47105
        total_water_liters_per_acre = round(total_water_liters_per_ha / hectare_to_acre)
        daily_avg_liters_per_acre = round((total_water / total_days) * 10000 / hectare_to_acre)
        
        print(f"Calculation completed: {total_water_liters_per_ha} L/ha ({total_water_liters_per_acre} L/acre), {len(irrigation_schedule)} irrigation events")

        return {
            'total_water_mm': total_water_mm,
            'total_water_liters_per_ha': total_water_liters_per_ha,
            'total_water_liters_per_acre': total_water_liters_per_acre,
            'irrigation_count': len(irrigation_schedule),
            'daily_avg_mm': round(total_water / total_days, 1),
            'daily_avg_liters_per_ha': round((total_water / total_days) * 10000, 0),
            'daily_avg_liters_per_acre': daily_avg_liters_per_acre,
            'schedule': irrigation_schedule
        }
    except Exception as e:
        print(f"Error in calculate_crop_water: {e}")
        import traceback
        traceback.print_exc()
        return None

# ================== MAIN FUNCTION ==================
def get_crop_water_requirements():
    """Get crop water requirements using real-time data from backend API"""
    
    # Fetch latest prediction data from the backend
    prediction_data = get_latest_prediction_data()
    
    if not prediction_data:
        print("Error: Could not fetch prediction data from API")
        return None
    
    # Format the data for calculations
    location, weather_data, crop_type, soil_type, plantation_date = format_prediction_data_for_calculations(prediction_data)
    
    if not crop_type or not soil_type or not plantation_date:
        print("Error: Missing required data from prediction API")
        return None
    
    print(f"Processing calculation for crop: {crop_type}, soil: {soil_type}, planting date: {plantation_date}")
    
    # Calculate water requirements
    result = calculate_crop_water(
        crop_name=crop_type,
        soil_type=soil_type,
        planting_date=plantation_date,
        weather_data=weather_data,
        location=location
    )
    
    if result:
        # Add original prediction data to the result
        result['input_data'] = prediction_data
    
    return result

def send_water_calculation_to_backend(calculation_result, base_url="https://ba7f-103-238-230-194.ngrok-free.app"):
    """Send water calculation result to backend API for storage"""
    # Use the correct endpoint for storing calculations
    endpoint = f"{base_url}/api/crop/store-prediction"
    
    try:
        # Get next water date from first irrigation event in schedule
        next_water_date = None
        water_frequency = 0
        
        if calculation_result['irrigation_count'] > 0 and len(calculation_result['schedule']) > 0:
            next_water_date = calculation_result['schedule'][0]['date']
            
            # Calculate average frequency between irrigation events
            if len(calculation_result['schedule']) > 1:
                dates = [datetime.strptime(irr['date'], "%Y-%m-%d") for irr in calculation_result['schedule']]
                intervals = [(dates[i+1] - dates[i]).days for i in range(len(dates)-1)]
                water_frequency = round(sum(intervals) / len(intervals))
            else:
                water_frequency = 7  # Default to weekly if only one irrigation event
        
        # Calculate days since planting
        planting_date = calculation_result['input_data']['plantation_date']
        try:
            plant_date = datetime.fromisoformat(planting_date.replace('Z', '+00:00'))
            days_since_planting = (datetime.now() - plant_date).days
        except:
            days_since_planting = 5  # Default if date parsing fails
        
        # Determine current growth stage
        try:
            crop_properties = load_crop_properties('crop_properties.csv')
            current_stage = determine_current_growth_stage(
                crop_properties, 
                calculation_result['input_data']['crop_type'],
                days_since_planting
            )
        except:
            current_stage = "initial"  # Default to initial stage if there's an error
        
        # Get water guidance for farmer
        water_guidance = get_water_depth_guidance(
            calculation_result['input_data']['crop_type'], 
            current_stage
        )
        
        # Convert to liters per acre
        hectare_to_acre = 2.47105
        liters_per_acre = round(calculation_result['total_water_liters_per_ha'] / hectare_to_acre)
        
        # Create simple instruction
        simple_instruction = f"Water your {calculation_result['input_data']['crop_type']} every {water_frequency} days. {water_guidance}."
        
        # Prepare the data for sending as required by the API
        payload = {
            'water_predicted': calculation_result['total_water_liters_per_ha'],
            'water_predicted_acre': liters_per_acre,
            'next_water_date': next_water_date,
            'water_frequency': water_frequency,
            #'water_guidance': water_guidance,
            'simple_instruction': simple_instruction
        }
        
        print(f"Sending calculation to backend: {payload}")
        
        # Send POST request to backend
        response = requests.post(endpoint, json=payload)
        
        if response.status_code == 200 or response.status_code == 201:
            print("Water calculation successfully sent to backend")
            return True
        else:
            print(f"Error sending calculation to backend: {response.status_code}")
            print(f"Response: {response.text}")
            return False
    except Exception as e:
        print(f"Exception when sending calculation to backend: {e}")
        import traceback
        traceback.print_exc()
        return False

# ================== EXECUTE MAIN CODE ==================
if __name__ == "__main__":
    try:
        print("========== CROP WATER CALCULATOR ==========")
        print(f"Starting execution at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        # Get water requirements
        result = get_crop_water_requirements()
        
        if result:
            # Print the results
            print("\n=== CROP WATER REQUIREMENTS ===")
            input_data = result['input_data']
            print(f"Crop: {input_data['crop_type']}")
            print(f"Soil Type: {input_data['soil_type']}")
            print(f"Total Water Volume: {result['total_water_liters_per_ha']} liters per hectare")
            print(f"Total Water Volume: {result['total_water_liters_per_acre']} liters per acre")
            print(f"Irrigation Events: {result['irrigation_count']}")
            
            if result['irrigation_count'] > 0:
                print(f"Next Water Date: {result['schedule'][0]['date']}")
                
                # Calculate days since planting
                planting_date = input_data['plantation_date']
                try:
                    plant_date = datetime.fromisoformat(planting_date.replace('Z', '+00:00'))
                    days_since_planting = (datetime.now() - plant_date).days
                except:
                    days_since_planting = 5  # Default if date parsing fails
                
                # Get current growth stage and guidance
                try:
                    crop_properties = load_crop_properties('crop_properties.csv')
                    current_stage = determine_current_growth_stage(
                        crop_properties, 
                        input_data['crop_type'],
                        days_since_planting
                    )
                    water_guidance = get_water_depth_guidance(input_data['crop_type'], current_stage)
                    print(f"Current Growth Stage: {current_stage}")
                    print(f"Water Guidance: {water_guidance}")
                except Exception as e:
                    print(f"Error getting growth stage and guidance: {e}")
            
            # Send results to backend
            send_successful = send_water_calculation_to_backend(result)
            if send_successful:
                print("Results successfully sent to database.")
            else:
                print("Failed to send results to database.")
        else:
            print("Failed to calculate water requirements.")
    except Exception as e:
        print(f"Error executing script: {e}")
        import traceback
        traceback.print_exc()
    
    print(f"Execution finished at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}") 