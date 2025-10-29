```sql
-- SQL Database Structure Definition for Personal Carbon Footprint Tracker

-- Table: Users
-- Stores user account information.
CREATE TABLE Users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Unique identifier for the user
    email VARCHAR(255) UNIQUE NOT NULL,                 -- User's email address (for login/identification)
    password_hash VARCHAR(255) NOT NULL,               -- Hashed password for security
    first_name VARCHAR(100),                          -- User's first name
    last_name VARCHAR(100),                           -- User's last name
    registration_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Date and time of registration
    last_login TIMESTAMP WITH TIME ZONE,              -- Last login date and time
    profile_picture_url VARCHAR(255),                 -- URL to user's profile picture
    prefers_metric BOOLEAN DEFAULT TRUE               -- User's preference for metric or imperial units
);

-- Table: UserSettings
-- Stores personalized settings for each user.
CREATE TABLE UserSettings (
    settings_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Unique identifier for settings
    user_id UUID UNIQUE NOT NULL REFERENCES Users(user_id) ON DELETE CASCADE, -- Foreign key to Users table
    notification_reminders_enabled BOOLEAN DEFAULT TRUE,    -- Whether reminders are enabled
    tip_notifications_enabled BOOLEAN DEFAULT TRUE,         -- Whether tip notifications are enabled
    default_currency VARCHAR(3) DEFAULT 'USD',              -- User's preferred currency
    default_transport_fuel_type VARCHAR(50) DEFAULT 'unleaded_petrol', -- Default fuel type for transport calculations (e.g., unleaded_petrol, electricity)
    default_electricity_source VARCHAR(50) DEFAULT 'grid_average' -- Default electricity source (e.g., grid_average, renewable)
);

-- Table: CarbonFootprintEntries
-- Stores individual data entries that contribute to the carbon footprint.
CREATE TABLE CarbonFootprintEntries (
    entry_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),    -- Unique identifier for the entry
    user_id UUID NOT NULL REFERENCES Users(user_id) ON DELETE CASCADE, -- Foreign key to Users table
    entry_date DATE NOT NULL,                               -- Date of the entry
    category VARCHAR(50) NOT NULL,                          -- Category of the footprint entry (e.g., 'Transportation', 'Energy', 'Diet', 'Waste')
    type VARCHAR(100) NOT NULL,                             -- Specific type within the category (e.g., 'Flight', 'Car', 'Electricity', 'Red Meat', 'Recycling')
    value DECIMAL(10, 2) NOT NULL,                          -- The quantitative value of the entry
    unit VARCHAR(50) NOT NULL,                              -- Unit of the value (e.g., 'km', 'miles', 'kWh', 'kg', 'portions')
    carbon_emissions_kg DECIMAL(10, 4) NOT NULL,            -- Calculated carbon emissions in kg CO2e for this entry
    description TEXT,                                       -- Optional description for the entry
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Timestamp when the entry was created
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP  -- Timestamp when the entry was last updated
);

-- Index for faster lookup of entries by user and date
CREATE INDEX idx_footprint_user_date ON CarbonFootprintEntries(user_id, entry_date);

-- Table: CarbonFootprintGoals
-- Allows users to set specific carbon reduction goals.
CREATE TABLE CarbonFootprintGoals (
    goal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),   -- Unique identifier for the goal
    user_id UUID NOT NULL REFERENCES Users(user_id) ON DELETE CASCADE, -- Foreign key to Users table
    start_date DATE NOT NULL,                             -- Start date of the goal
    end_date DATE NOT NULL,                               -- End date of the goal
    initial_footprint_kg DECIMAL(10, 4) NOT NULL,         -- User's footprint at the start of the goal period (kg CO2e)
    target_footprint_kg DECIMAL(10, 4) NOT NULL,          -- Target footprint to achieve by the end date (kg CO2e)
    target_percentage_reduction DECIMAL(5, 2) NOT NULL,   -- Target percentage reduction (e.g., 10.00 for 10%)
    status VARCHAR(20) DEFAULT 'active',                 -- Current status of the goal ('active', 'achieved', 'failed')
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Timestamp when the goal was created
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP  -- Timestamp when the goal was last updated
);

-- Index for faster lookup of goals by user
CREATE INDEX idx_goals_user_id ON CarbonFootprintGoals(user_id);

-- Table: SustainabilityTips
-- Stores a library of actionable sustainability tips.
CREATE TABLE SustainabilityTips (
    tip_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Unique identifier for the tip
    title VARCHAR(255) NOT NULL,                       -- Title of the tip
    content TEXT NOT NULL,                             -- Detailed content of the tip
    category VARCHAR(50) NOT NULL,                     -- Category this tip applies to (e.g., 'Transportation', 'Energy', 'Diet')
    impact_level VARCHAR(20) DEFAULT 'medium',         -- Estimated impact level ('low', 'medium', 'high')
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP -- Timestamp when the tip was added
);

-- Table: UserTipsInteraction
-- Tracks which tips users have viewed, saved, or marked as 'done'.
CREATE TABLE UserTipsInteraction (
    interaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Unique identifier for the interaction
    user_id UUID NOT NULL REFERENCES Users(user_id) ON DELETE CASCADE, -- Foreign key to Users table
    tip_id UUID NOT NULL REFERENCES SustainabilityTips(tip_id) ON DELETE CASCADE, -- Foreign key to SustainabilityTips table
    status VARCHAR(20) NOT NULL,                       -- Interaction status ('viewed', 'saved', 'implemented', 'dismissed')
    interaction_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Date of interaction
    UNIQUE (user_id, tip_id, status) -- Ensures unique combination of user, tip, and status
);

-- Table: EducationalResources
-- Stores in-app educational content.
CREATE TABLE EducationalResources (
    resource_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Unique identifier for the resource
    title VARCHAR(255) NOT NULL,                         -- Title of the resource
    content TEXT NOT NULL,                               -- Full content of the resource (can be markdown/HTML)
    category VARCHAR(100) NOT NULL,                      -- Category (e.g., 'What is Carbon Footprint?', 'Renewable Energy', 'Sustainable Diet')
    resource_type VARCHAR(50) DEFAULT 'article',         -- Type of resource ('article', 'infographic', 'video_link')
    external_link VARCHAR(255),                          -- Optional link to external resource (e.g., YouTube video)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP -- Timestamp when the resource was added
);

-- Table: CarbonFactors
-- Stores the emission factors used for calculations. This table would be managed by admins.
CREATE TABLE CarbonFactors (
    factor_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Unique identifier for the factor
    category VARCHAR(50) NOT NULL,                        -- Category (e.g., 'Transportation', 'Energy', 'Diet', 'Waste')
    type VARCHAR(100) NOT NULL,                           -- Specific type (e.g., 'Flight_long_haul', 'Electricity_grid_average', 'Red_Meat_per_kg')
    unit VARCHAR(50) NOT NULL,                            -- Unit for the factor (e.g., 'km', 'kWh', 'kg')
    emissions_kg_per_unit DECIMAL(10, 6) NOT NULL,        -- KG CO2e per unit
    region VARCHAR(100),                                  -- Optional: region-specific factor (e.g., 'Global', 'USA', 'EU')
    source VARCHAR(255),                                  -- Source of the data (e.g., 'DEFRA', 'EPA')
    effective_from DATE DEFAULT CURRENT_DATE,             -- Date from which this factor is effective
    effective_to DATE,                                    -- Date until which this factor is effective (NULL if current)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (category, type, unit, region, effective_from) -- Ensure unique factor combinations
);

-- Example Data for CarbonFactors (Illustrative)
INSERT INTO CarbonFactors (category, type, unit, emissions_kg_per_unit, region, source) VALUES
  ('Transportation', 'Flight_short_haul', 'km', 0.15, 'Global', 'ECAA'),
  ('Transportation', 'Flight_medium_haul', 'km', 0.12, 'Global', 'ECAA'),
  ('Transportation', 'Flight_long_haul', 'km', 0.10, 'Global', 'ECAA'),
  ('Transportation', 'Car_petrol', 'km', 0.192, 'Global', 'EPA'), -- Average passenger car, 2.31 kg CO2/gallon, 8.9L/100km
  ('Transportation', 'Car_diesel', 'km', 0.171, 'Global', 'EPA'),
  ('Transportation', 'Car_electric', 'km', 0.05, 'Global', 'Grid Average'), -- Depends heavily on grid
  ('Energy', 'Electricity_grid_average', 'kWh', 0.233, 'Global', 'IEA'), -- Global average
  ('Energy', 'Electricity_renewable', 'kWh', 0.01, 'Global', 'Various'), -- Small emissions from infrastructure
  ('Diet', 'Red_Meat_beef', 'kg', 27.0, 'Global', 'Poore & Nemecek'),
  ('Diet', 'Poultry', 'kg', 6.9, 'Global', 'Poore & Nemecek'),
  ('Diet', 'Dairy_milk', 'liter', 1.0, 'Global', 'Poore & Nemecek'),
  ('Waste', 'Waste_landfill', 'kg', 1.0, 'Global', 'EPA Est.'), -- Highly variable, simple estimate
  ('Waste', 'Waste_recycled', 'kg', -0.5, 'Global', 'EPA Est.'); -- Negative for avoided emissions

-- Table: UserActivities
-- Tracks specific actions performed by the user for reminders or nudges.
CREATE TABLE UserActivities (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Unique identifier for the activity
    user_id UUID NOT NULL REFERENCES Users(user_id) ON DELETE CASCADE, -- Foreign key to Users table
    activity_type VARCHAR(100) NOT NULL,                 -- Type of activity (e.g., 'data_entry_today', 'tip_implemented', 'goal_updated')
    activity_details JSONB,                              -- JSON object for specific details of the activity (e.g., {"category": "Transportation"})
    activity_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP -- Timestamp of the activity
);

-- Table: Integrations
-- Stores information about potential future integrations (e.g., smart home devices, health apps).
CREATE TABLE Integrations (
    integration_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Unique identifier for the integration
    user_id UUID NOT NULL REFERENCES Users(user_id) ON DELETE CASCADE, -- Foreign key to Users table
    integration_name VARCHAR(100) NOT NULL,               -- Name of the integrated service (e.g., 'Smart Meter API', 'Flight Tracking')
    auth_token TEXT,                                      -- Securely stored authentication token
    status VARCHAR(20) DEFAULT 'active',                 -- Status of the integration ('active', 'disconnected')
    last_synced TIMESTAMP WITH TIME ZONE,                 -- Last time data was synced
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

```