# Cloud Web App

## Overview

This project is a cloud-native backend API developed using **Node.js** and **Express.js**, designed to meet cloud-native web application requirements. The API provides a health check endpoint (`/healthz`) to monitor the health of the application and its connection to the database. It uses **PostgreSQL** for the database.

## Features

- **Health Check Endpoint**: `/healthz` checks the database connection and returns an appropriate status code:
  - `200 OK` if the database connection is successful.
  - `503 Service Unavailable` if the database connection fails.
  - `405 Method Not Allowed` for unsupported HTTP methods.
  - `400 Bad Request` if any payload is provided.
- **User Management Endpoints**:
  - Create a new user (`/v1/user`).
  - Get user information (`/v1/user/self`).
- **Secure Password Handling**: Passwords are hashed using **bcrypt** before storing in the database.
- **No Caching**: The API response includes `Cache-Control: no-cache` and `Pragma: no-cache` headers to ensure that the responses are not cached.

## Prerequisites

Before running the application, ensure that you have the following installed:

- **Node.js** (v16.x or higher)
- **npm** (comes with Node.js)
- **PostgreSQL** (v13.x or higher)

## Setup

1. **Clone the repository**:

   ```bash
   git clone https://github.com/002478905/cloud-web-app.git
   cd cloud-web-app
   ```

2. **Install dependencies**:

   ```bash
   npm install
   ```

3. **Configure PostgreSQL Connection**:

   Update the PostgreSQL connection details in `index.js`:

   ```javascript
   const pool = new Pool({
     user: "your_db_user",
     host: "localhost",
     database: "your_db_name",
     password: "your_db_password",
     port: 5432,
   });
   ```

4. **Run the Application**:

   ```bash
   node index.js
   ```

   The server will start at `http://localhost:8080`.

## API Endpoints

### **GET /healthz**

- **Description**: This endpoint checks if the application is connected to the PostgreSQL database.
- **Response Codes**:
  - `200 OK`: Database connection is successful.
  - `503 Service Unavailable`: Database connection fails.
  - `400 Bad Request`: Request contains a payload (which is not allowed).
  - `405 Method Not Allowed`: If any HTTP method other than GET is used.
- **Response Headers**:
  - `Cache-Control: no-cache, no-store, must-revalidate`
  - `Pragma: no-cache`
- **No response body** is returned.

#### Example Requests

- **Success**:

  ```bash
  curl -X GET http://localhost:8080/healthz
  ```

- **Failure**:
  Stop the PostgreSQL server and run the same command. You should receive `503 Service Unavailable`.

- **Invalid Method**:

  ```bash
  curl -X PUT http://localhost:8080/healthz
  ```

- **Payload Not Allowed**:
  ```bash
  curl -X GET http://localhost:8080/healthz -d '{"key":"value"}'
  ```

## Running Tests

You can manually test the endpoints using Postman or cURL, as shown in the examples above.
