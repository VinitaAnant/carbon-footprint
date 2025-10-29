```markdown
# API Specification: Personal Carbon Footprint Tracker

This document outlines the API endpoints, data models, and business logic for the Personal Carbon Footprint Tracker application.

## 1. Authentication and Authorization

All API endpoints, unless explicitly stated, will require authentication. We will use a standard token-based authentication mechanism (e.g., JWT). Authorization will be handled by requiring a valid user token for all actions related to a user's personal data.

**Auth Endpoints (Example Draft - Specifics determined by authentication provider)**

*   `POST /auth/register`: User registration.
*   `POST /auth/login`: User login, returns authentication token.
*   `POST /auth/refresh-token`: Refresh an expiring token.
*   `POST /auth/logout`: Invalidate current session token.

## 2. API Endpoints

### 2.1 User Management

#### 2.1.1 Get User Profile

Retrieves the authenticated user's profile information.

*   `GET /users/me`

**Business Logic:**
*   Returns basic user details. Does not include sensitive information like hashed passwords.

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>`

**Response (200 OK):**
```json
{
  "id": "uuid-user-123",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "createdAt": "2023-10-27T10:00:00Z"
}
```

#### 2.1.2 Update User Profile

Updates the authenticated user's profile information.

*   `PUT /users/me`

**Business Logic:**
*   Only specific fields (e.g., `firstName`, `lastName`) can be updated by the user. Email changes might require re-verification.

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>`
*   **Body (application/json):**
```json
{
  "firstName": "Jonathan",
  "lastName": "Smith"
}
```

**Response (200 OK):**
```json
{
  "id": "uuid-user-123",
  "email": "user@example.com",
  "firstName": "Jonathan",
  "lastName": "Smith",
  "createdAt": "2023-10-27T10:00:00Z"
}
```

### 2.2 Carbon Footprint Data Entry

This section covers APIs for inputting various types of carbon-contributing activities.

**General Business Logic for Data Entry:**
*   All data entries are associated with a specific user and a timestamp.
*   Input validation will be performed on all fields (e.g., positive numbers for quantities, valid date formats).
*   Each entry will trigger an update to the user's overall carbon footprint calculation.

#### 2.2.1 Create Transportation Entry

Records a transportation activity.

*   `POST /footprint/transportation`

**Business Logic:**
*   Based on `transportMode` and `distance` (or `fuelConsumption` for `car`), calculate the CO2e emissions using predefined emission factors.
*   Emission factors for different modes will be stored in the backend and updated periodically.
    *   **Car:** `distance` (km) * `fuelEfficiency` (L/100km) * `fuelType` emission factor (kg CO2e/L) OR `distance` (km) * `carType` emission factor (kg CO2e/km).
    *   **Flight:** `distance` (km) * `flightClass` emission factor (kg CO2e/km, considering radiative forcing). Short vs. long haul factors might vary.
    *   **Public Transport (Bus/Train):** `distance` (km) * `mode` emission factor (kg CO2e/km).
*   The system will automatically store the calculated `carbonEmissions` value.

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>`
*   **Body (application/json):**
```json
{
  "activityDate": "2023-10-26T14:30:00Z",
  "transportMode": "car",              // "car", "flight", "bus", "train"
  "distanceKm": 150.5,                 // Required for all modes
  "fuelType": "gasoline",              // Required for "car": "gasoline", "diesel", "electric"
  "fuelEfficiencyLitersPer100Km": 7.5, // Optional for "car", if not provided, average car factor will be used
  "flightClass": "economy",            // Optional for "flight": "economy", "business", "first"
  "departureAirportCode": "LHR",       // Optional for "flight"
  "arrivalAirportCode": "JFK",         // Optional for "flight"
  "notes": "Weekend trip to the coast"
}
```

**Response (201 Created):**
```json
{
  "id": "uuid-transport-entry-1",
  "userId": "uuid-user-123",
  "activityDate": "2023-10-26T14:30:00Z",
  "transportMode": "car",
  "distanceKm": 150.5,
  "fuelType": "gasoline",
  "fuelEfficiencyLitersPer100Km": 7.5,
  "carbonEmissionsKgCO2e": 26.54, // Calculated value
  "notes": "Weekend trip to the coast",
  "createdAt": "2023-10-27T10:05:00Z"
}
```

#### 2.2.2 Create Energy Consumption Entry

Records home energy consumption.

*   `POST /footprint/energy`

**Business Logic:**
*   Calculate CO2e emissions based on `energySource` (electricity, natural gas) and `consumptionUnit` (kWh, m³).
*   Use country-specific grid emission factors for electricity (kg CO2e/kWh) and standard emission factors for natural gas (kg CO2e/m³).
*   Allow specifying `startDate` and `endDate` for billing periods. If only `activityDate` is provided, assume a single day's consumption.

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>`
*   **Body (application/json):**
```json
{
  "activityDate": "2023-10-26T00:00:00Z", // Date of entry or start date of period
  "energySource": "electricity",       // "electricity", "natural_gas"
  "consumptionValue": 250,             // e.g., 250 kWh, 50 m3
  "consumptionUnit": "kWh",            // "kWh", "cubic_meters"
  "countryCode": "US",                 // For country-specific grid emission factors
  "startDate": "2023-10-01T00:00:00Z", // Optional, for billing periods
  "endDate": "2023-10-31T23:59:59Z",   // Optional, for billing periods
  "notes": "Monthly electricity bill"
}
```

**Response (201 Created):**
```json
{
  "id": "uuid-energy-entry-1",
  "userId": "uuid-user-123",
  "activityDate": "2023-10-26T00:00:00Z",
  "energySource": "electricity",
  "consumptionValue": 250,
  "consumptionUnit": "kWh",
  "countryCode": "US",
  "carbonEmissionsKgCO2e": 95.00, // Calculated value (e.g., 0.38 kg CO2e/kWh for US)
  "notes": "Monthly electricity bill",
  "createdAt": "2023-10-27T10:10:00Z"
}
```

#### 2.2.3 Create Diet Entry

Records dietary choices.

*   `POST /footprint/diet`

**Business Logic:**
*   Calculate CO2e emissions based on `dietaryOption` and `frequency`.
*   Predefined emission factors for common dietary choices (e.g., amount of beef vs. vegetarian meals).
*   Simplified approach: users select general dietary patterns. More complex models involving specific food items or portions could be a future enhancement.

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>`
*   **Body (application/json):**
```json
{
  "activityDate": "2023-10-26T12:00:00Z",
  "dietaryOption": "high_meat",        // "vegan", "vegetarian", "low_meat", "regular_meat", "high_meat"
  "frequency": "daily",                // "daily", "weekly", "monthly", "single_meal" (could be used with quantity)
  "notes": "Tracking my typical week"
}
```

**Response (201 Created):**
```json
{
  "id": "uuid-diet-entry-1",
  "userId": "uuid-user-123",
  "activityDate": "2023-10-26T12:00:00Z",
  "dietaryOption": "high_meat",
  "frequency": "daily",
  "carbonEmissionsKgCO2e": 15.0, // Example daily value based on category
  "notes": "Tracking my typical week",
  "createdAt": "2023-10-27T10:15:00Z"
}
```

#### 2.2.4 Create Waste Entry

Records waste generation.

*   `POST /footprint/waste`

**Business Logic:**
*   Calculate CO2e emissions based on `wasteType` and `weightKg`.
*   Emission factors for different waste types (e.g., general waste to landfill, recycling, composting).

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>`
*   **Body (application/json):**
```json
{
  "activityDate": "2023-10-26T09:00:00Z",
  "wasteType": "general",              // "general", "recycling", "compost"
  "weightKg": 2.5,
  "notes": "Weekly bin collection"
}
```

**Response (201 Created):**
```json
{
  "id": "uuid-waste-entry-1",
  "userId": "uuid-user-123",
  "activityDate": "2023-10-26T09:00:00Z",
  "wasteType": "general",
  "weightKg": 2.5,
  "carbonEmissionsKgCO2e": 1.2, // Calculated value
  "notes": "Weekly bin collection",
  "createdAt": "2023-10-27T10:20:00Z"
}
```

#### 2.2.5 Get All Footprint Entries (Filtered)

Retrieves all carbon footprint entries for the authenticated user, with optional filtering.

*   `GET /footprint/entries`

**Business Logic:**
*   Allows filtering by date range and category to support detailed analysis and historical views.
*   Pagination should be implemented for large datasets.

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>`
*   **Query Parameters (Optional):**
    *   `startDate`: `YYYY-MM-DD` (e.g., `2023-01-01`)
    *   `endDate`: `YYYY-MM-DD` (e.g., `2023-12-31`)
    *   `category`: `transportation`, `energy`, `diet`, `waste`
    *   `page`: `1` (default)
    *   `limit`: `10` (default)

**Response (200 OK):**
```json
{
  "totalItems": 4,
  "currentPage": 1,
  "totalPages": 1,
  "data": [
    {
      "id": "uuid-transport-entry-1",
      "type": "transportation",
      "activityDate": "2023-10-26T14:30:00Z",
      "carbonEmissionsKgCO2e": 26.54,
       "details": { /* specific fields based on type */
         "transportMode": "car",
         "distanceKm": 150.5
       }
    },
    {
      "id": "uuid-energy-entry-1",
      "type": "energy",
      "activityDate": "2023-10-26T00:00:00Z",
      "carbonEmissionsKgCO2e": 95.00,
      "details": {
         "energySource": "electricity",
         "consumptionValue": 250
      }
    },
    // ... other entries
  ]
}
```

### 2.3 Carbon Footprint Analysis & Reporting

#### 2.3.1 Get Current Carbon Footprint Breakdown

Provides a breakdown of the user's carbon footprint for a specified period.

*   `GET /footprint/breakdown`

**Business Logic:**
*   Aggregates `carbonEmissionsKgCO2e` values from all relevant entries within the specified `startDate` and `endDate`.
*   Calculates total emissions and a percentage breakdown by primary categories (`transportation`, `energy`, `diet`, `waste`).
*   Default period could be "current month" if no dates are provided.

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>`
*   **Query Parameters (Optional):**
    *   `startDate`: `YYYY-MM-DD` (e.g., `2023-10-01`)
    *   `endDate`: `YYYY-MM-DD` (e.g., `2023-10-31`)
    *   `period`: `daily`, `weekly`, `monthly`, `yearly` (If provided, `startDate`/`endDate` will default to current period)

**Response (200 OK):**
```json
{
  "periodStart": "2023-10-01T00:00:00Z",
  "periodEnd": "2023-10-31T23:59:59Z",
  "totalCarbonEmissionsKgCO2e": 250.75, // Sum of all entries in the period
  "breakdown": {
    "transportation": {
      "emissionsKgCO2e": 120.50,
      "percentage": 48.06
    },
    "energy": {
      "emissionsKgCO2e": 95.00,
      "percentage": 37.89
    },
    "diet": {
      "emissionsKgCO2e": 30.00,
      "percentage": 11.96
    },
    "waste": {
      "emissionsKgCO2e": 5.25,
      "percentage": 2.09
    },
    "other": { // Potentially for future categories
      "emissionsKgCO2e": 0.00,
      "percentage": 0.00
    }
  }
}
```

#### 2.3.2 Get Historical Footprint Trend

Provides time-series data of the user's carbon footprint.

*   `GET /footprint/trend`

**Business Logic:**
*   Aggregates total carbon emissions over specified intervals (e.g., daily, weekly, monthly).
*   Allows users to visualize their footprint changes over time.

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>`
*   **Query Parameters:**
    *   `interval`: `daily`, `weekly`, `monthly` (Required)
    *   `startDate`: `YYYY-MM-DD` (Required)
    *   `endDate`: `YYYY-MM-DD` (Required)

**Response (200 OK):**
```json
{
  "interval": "monthly",
  "data": [
    {
      "period": "2023-08",
      "totalCarbonEmissionsKgCO2e": 650.20
    },
    {
      "period": "2023-09",
      "totalCarbonEmissionsKgCO2e": 580.10
    },
    {
      "period": "2023-10",
      "totalCarbonEmissionsKgCO2e": 250.75 // This month might be incomplete
    }
  ]
}
```

### 2.4 Goal Setting & Progress Tracking

#### 2.4.1 Create Carbon Reduction Goal

Allows a user to set a new carbon reduction goal.

*   `POST /goals`

**Business Logic:**
*   A goal has a `targetPercentageReduction` and a `targetDate`.
*   The `currentBaselineKgCO2e` should be calculated based on the user's footprint over a recent historical period (e.g., last 30 days) to establish a benchmark for the goal.
*   Only one *active* goal can exist at a time. Previous goals can be archived or marked as completed.

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>`
*   **Body (application/json):**
```json
{
  "targetPercentageReduction": 15, // e.g., 15% reduction
  "targetDate": "2024-03-31T23:59:59Z",
  "name": "Reduce my footprint by 15% in 5 months"
}
```

**Response (201 Created):**
```json
{
  "id": "uuid-goal-1",
  "userId": "uuid-user-123",
  "name": "Reduce my footprint by 15% in 5 months",
  "targetPercentageReduction": 15,
  "targetDate": "2024-03-31T23:59:59Z",
  "currentBaselineKgCO2e": 500.0, // Calculated based on recent avg footprint
  "targetEmissionsKgCO2e": 425.0, // 500 * (1 - 0.15)
  "status": "active",             // "active", "completed", "failed", "archived"
  "createdAt": "2023-10-27T10:30:00Z"
}
```

#### 2.4.2 Get User Goals

Retrieves carbon reduction goals for the authenticated user.

*   `GET /goals`

**Business Logic:**
*   Allows fetching active, completed, or all goals.

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>`
*   **Query Parameters (Optional):**
    *   `status`: `active`, `completed`, `failed`, `archived` (default: `active`)

**Response (200 OK):**
```json
[
  {
    "id": "uuid-goal-1",
    "userId": "uuid-user-123",
    "name": "Reduce my footprint by 15% in 5 months",
    "targetPercentageReduction": 15,
    "targetDate": "2024-03-31T23:59:59Z",
    "currentBaselineKgCO2e": 500.0,
    "targetEmissionsKgCO2e": 425.0,
    "currentProgressKgCO2e": 480.0, // User's current average from start of goal to now
    "progressPercentage": 4.0,      // (Baseline - Current) / (Baseline - Target) * 100
    "status": "active",
    "createdAt": "2023-10-27T10:30:00Z",
    "updatedAt": "2023-11-20T11:00:00Z"
  }
]
```

### 2.5 Sustainability Tips & Educational Resources

#### 2.5.1 Get Personalized Sustainability Tips

Retrieves sustainability tips relevant to the user's current footprint.

*   `GET /tips`

**Business Logic:**
*   Analyze the user's `footprint/breakdown` (e.g., if transportation is the highest contributor, suggest transportation-related tips).
*   Tips can be categorized (e.g., `transportation`, `energy`, `diet`, `waste`).
*   Tips can also be marked as `actionable` (direct changes) or `educational` (knowledge building).
*   Avoid recommending tips already marked as "completed" by the user.

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>`
*   **Query Parameters (Optional):**
    *   `category`: `transportation`, `energy`, `diet`, `waste`
    *   `type`: `actionable`, `educational`
    *   `limit`: `5` (default)

**Response (200 OK):**
```json
[
  {
    "id": "uuid-tip-1",
    "title": "Try a Vegetarian Meal Once a Week",
    "description": "Switching to plant-based meals can significantly reduce your food-related carbon footprint. Start with one meal a week!",
    "category": "diet",
    "type": "actionable",
    "estimatedImpactKgCO2ePerMonth": 10.0, // Example impact
    "isCompleted": false
  },
  {
    "id": "uuid-tip-2",
    "title": "Understanding Your Electricity Bill",
    "description": "Learn how to read your electricity bill to identify peak usage times and opportunities for savings and reduction.",
    "category": "energy",
    "type": "educational",
    "estimatedImpactKgCO2ePerMonth": null, // No direct impact
    "isCompleted": false
  }
]
```

#### 2.5.2 Mark Tip as Completed/Actioned

Updates the status of a sustainability tip for the user.

*   `PUT /tips/{tipId}/status`

**Business Logic:**
*   Marks a tip as completed by the user. This helps personalize future tip recommendations.

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>`
*   **Path Parameters:**
    *   `tipId`: ID of the tip to update.
*   **Body (application/json):**
```json
{
  "status": "completed" // "completed", "dismissed"
}
```

**Response (200 OK):**
```json
{
  "id": "uuid-tip-1",
  "title": "Try a Vegetarian Meal Once a Week",
  "status": "completed"
}
```

#### 2.5.3 Get Educational Resources

Retrieves general educational content related to sustainability.

*   `GET /resources`

**Business Logic:**
*   Provides access to a curated list of articles, videos, or external links.

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>` (Optional, but good for tracking engagement)
*   **Query Parameters (Optional):**
    *   `category`: `climate_change`, `sustainable_living`, `carbon_footprint_basics`

**Response (200 OK):**
```json
[
  {
    "id": "uuid-resource-1",
    "title": "What is Carbon Footprint?",
    "description": "An introduction to what a carbon footprint is and why it matters.",
    "type": "article",
    "url": "https://example.com/article/carbon-footprint-basics",
    "category": "carbon_footprint_basics",
    "thumbnailUrl": "https://example.com/images/carbon-footprint-thumb.jpg"
  },
  {
    "id": "uuid-resource-2",
    "title": "Documentary: Our Planet - Episode 1",
    "description": "Explore the natural world and the impact of climate change.",
    "type": "video",
    "url": "https://example.com/video/our-planet-ep1",
    "category": "climate_change",
    "thumbnailUrl": "https://example.com/images/our-planet-ep1-thumb.jpg"
  }
]
```

### 2.6 Reminders & Nudges

#### 2.6.1 Get User Reminders

Retrieves scheduled reminders for the user.

*   `GET /reminders`

**Business Logic:**
*   Users can configure reminders for data entry or goal tracking.

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>`

**Response (200 OK):**
```json
[
  {
    "id": "uuid-reminder-1",
    "type": "data_entry",       // "data_entry", "goal_checkin", "tip_action"
    "message": "Don't forget to log your transportation this week!",
    "frequency": "weekly",
    "dayOfWeek": "monday",
    "timeOfDay": "18:00",
    "isActive": true
  },
  {
    "id": "uuid-reminder-2",
    "type": "goal_checkin",
    "message": "It's time to check in on your carbon reduction goal!",
    "frequency": "monthly",
    "dayOfMonth": 1,
    "timeOfDay": "09:00",
    "isActive": true
  }
]
```

#### 2.6.2 Create/Update Reminder

Creates a new reminder or updates an existing one.

*   `POST /reminders` (Create)
*   `PUT /reminders/{reminderId}` (Update)

**Business Logic:**
*   Validate `frequency` with related time parameters (e.g., `dayOfWeek` for weekly, `dayOfMonth` for monthly).

**Request (POST Example):**
*   **Headers:**
    *   `Authorization: Bearer <token>`
*   **Body (application/json):**
```json
{
  "type": "data_entry",
  "message": "Time to log your daily diet!",
  "frequency": "daily",
  "timeOfDay": "20:00",
  "isActive": true
}
```

**Response (201 Created / 200 OK):**
```json
{
  "id": "uuid-reminder-3",
  "userId": "uuid-user-123",
  "type": "data_entry",
  "message": "Time to log your daily diet!",
  "frequency": "daily",
  "timeOfDay": "20:00",
  "isActive": true,
  "createdAt": "2023-10-27T10:45:00Z"
}
```

#### 2.6.3 Delete Reminder

Deletes a reminder.

*   `DELETE /reminders/{reminderId}`

**Business Logic:**
*   Only the owner of the reminder can delete it.

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>`

**Response (204 No Content):**

### 2.7 Data Export / Sharing (Optional)

#### 2.7.1 Export Footprint Data

Allows users to export their carbon footprint data.

*   `GET /export/footprint`

**Business Logic:**
*   Consolidates all user's historical footprint entries into a structured format (e.g., CSV, JSON).
*   Allows filtering by date range.
*   The export process might be asynchronous for very large datasets, notifying the user when the file is ready.

**Request:**
*   **Headers:**
    *   `Authorization: Bearer <token>`
*   **Query Parameters (Optional):**
    *   `format`: `csv`, `json` (default `csv`)
    *   `startDate`: `YYYY-MM-DD`
    *   `endDate`: `YYYY-MM-DD`

**Response (200 OK - application/csv or application/json):**
*   Returns the raw file data.

## 3. Data Models (Conceptual)

### User
*   `id` (UUID)
*   `email` (string, unique)
*   `passwordHash` (string)
*   `firstName` (string)
*   `lastName` (string)
*   `createdAt` (datetime)
*   `updatedAt` (datetime)

### CarbonEntry (Polymorphic or separate tables for each type)
*   `id` (UUID)
*   `userId` (UUID, FK to User)
*   `type` (enum: `transportation`, `energy`, `diet`, `waste`)
*   `activityDate` (datetime)
*   `carbonEmissionsKgCO2e` (decimal, calculated)
*   `notes` (string, optional)
*   `createdAt` (datetime)
*   `updatedAt` (datetime)

#### TransportationEntry (extends CarbonEntry)
*   `transportMode` (enum)
*   `distanceKm` (decimal)
*   `fuelType` (enum, optional)
*   `fuelEfficiencyLitersPer100Km` (decimal, optional)
*   `flightClass` (enum, optional)
*   `departureAirportCode` (string, optional)
*   `arrivalAirportCode` (string, optional)

#### EnergyEntry (extends CarbonEntry)
*   `energySource` (enum)
*   `consumptionValue` (decimal)
*   `consumptionUnit` (enum: `kWh`, `cubic_meters`)
*   `countryCode` (string, ISO 3166-1 alpha-2)
*   `startDate` (datetime, optional)
*   `endDate` (datetime, optional)

#### DietEntry (extends CarbonEntry)
*   `dietaryOption` (enum: `vegan`, `vegetarian`, `low_meat`, `regular_meat`, `high_meat`)
*   `frequency` (enum: `daily`, `weekly`, `monthly`, `single_meal`)

#### WasteEntry (extends CarbonEntry)
*   `wasteType` (enum: `general`, `recycling`, `compost`)
*   `weightKg` (decimal)

### Goal
*   `id` (UUID)
*   `userId` (UUID, FK to User)
*   `name` (string)
*   `targetPercentageReduction` (integer)
*   `targetDate` (datetime)
*   `currentBaselineKgCO2e` (decimal)
*   `targetEmissionsKgCO2e` (decimal, calculated)
*   `status` (enum: `active`, `completed`, `failed`, `archived`)
*   `createdAt` (datetime)
*   `updatedAt` (datetime)
*   `completedDate` (datetime, optional)

### Tip
*   `id` (UUID)
*   `title` (string)
*   `description` (string)
*   `category` (enum: `transportation`, `energy`, `diet`, `waste`, `general`)
*   `type` (enum: `actionable`, `educational`)
*   `estimatedImpactKgCO2ePerMonth` (decimal, optional)
*   `source` (string, optional)
*   `createdAt` (datetime)

### UserTipStatus (Join table to track user interaction with tips)
*   `userId` (UUID, FK to User)
*   `tipId` (UUID, FK to Tip)
*   `status` (enum: `pending`, `completed`, `dismissed`)
*   `lastViewedAt` (datetime)
*   `updatedAt` (datetime)

### Resource
*   `id` (UUID)
*   `title` (string)
*   `description` (string)
*   `type` (enum: `article`, `video`, `external_link`)
*   `url` (string)
*   `category` (enum: `climate_change`, `sustainable_living`, `carbon_footprint_basics`)
*   `thumbnailUrl` (string, optional)
*   `createdAt` (datetime)

### Reminder
*   `id` (UUID)
*   `userId` (UUID, FK to User)
*   `type` (enum: `data_entry`, `goal_checkin`, `tip_action`)
*   `message` (string)
*   `frequency` (enum: `daily`, `weekly`, `monthly`)
*   `dayOfWeek` (enum: `monday`...`sunday`, required for weekly)
*   `dayOfMonth` (integer, required for monthly)
*   `timeOfDay` (string, format `HH:MM`)
*   `isActive` (boolean)
*   `createdAt` (datetime)
*   `updatedAt` (datetime)

## 4. Emission Factors & Configuration

Emission factors will be externalized and managed centrally on the backend. They will not be directly exposed via the API to client applications but will be used in calculations.

**Examples of Emission Factors:**
*   **Electricity:** `countryCode` -> `kgCO2e_per_kWh` (e.g., US: 0.38, Sweden: 0.01)
*   **Gasoline:** `kgCO2e_per_liter` (e.g., 2.31 kg CO2e/L)
*   **Diesel:** `kgCO2e_per_liter` (e.g., 2.68 kg CO2e/L)
*   **Car (average):** `kgCO2e_per_km` (e.g., 0.17 kg CO2e/km)
*   **Flight (Economy):** `kgCO2e_per_pkm` (passenger-kilometer, variable by distance and radiative forcing factor)
*   **Dietary Options:** `kgCO2e_per_day` or `kgCO2e_per_meal` for each category (e.g., 'high_meat' might be 15 kgCO2e/day)
*   **Waste (General to Landfill):** `kgCO2e_per_kg` (e.g., 0.48 kg CO2e/kg)

These factors need to be periodically reviewed and updated to reflect the latest scientific data and national averages.

## 5. Error Handling

Standard HTTP status codes will be used for API responses:

*   `200 OK`: Successful GET, PUT, DELETE with content.
*   `201 Created`: Successful POST.
*   `204 No Content`: Successful DELETE where no content is returned (e.g., deleting a reminder).
*   `400 Bad Request`: Invalid input, validation errors.
*   `401 Unauthorized`: Missing or invalid authentication token.
*   `403 Forbidden`: Authenticated but does not have permission to access the resource.
*   `404 Not Found`: Resource not found.
*   `409 Conflict`: Resource creation conflict (e.g., creating a goal when an active one exists).
*   `500 Internal Server Error`: Server-side errors.

Error responses will typically include a machine-readable message and potentially details about the error.

```json
{
  "code": "BAD_REQUEST",
  "message": "Validation failed",
  "details": [
    {
      "field": "distanceKm",
      "error": "Must be a positive number"
    },
    {
      "field": "transportMode",
      "error": "Invalid transport mode"
    }
  ]
}
```
```