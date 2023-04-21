
# Step to run the project -- docker-compose up

## All the API will be exposed on localhost:3000


# Login API documentation

## Actions

### `POST /login/user`

This action creates a new user in the database with the provided email and password. It takes the following parameters in the request body:

- `email` (string): The user's email address.
- `password` (string): The user's password.

Example Request:
```
POST /login/user HTTP/1.1
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

If a user with the same email address already exists in the database, an error message is returned with a status of `unprocessable_entity`. Example Response:
```
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/json

{
  "error": "user with email user@example.com already exists"
}
```

Otherwise, a JSON object is returned containing the new user's ID and email address. Example Response:
```
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": 1,
  "email": "user@example.com"
}
```


### `POST /login/user/token`

This action creates a new JWT token for the user based on their email and password. It takes the following parameters in the request body:

- `email` (string): The user's email address.
- `password` (string): The user's password.

Example Request:
```
POST /login/user/token HTTP/1.1
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

If the email and password match a user in the database, a JSON object is returned containing the JWT token. Example Response:
```
HTTP/1.1 200 OK
Content-Type: application/json

{
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoyLCJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20iLCJleHAiOjE2MzcyMjMxODd9.7ESQ-jyhiH1FAJL6Ubj_z6ETC9b8LnD6l1HnU_YxEyQ"
}
```
By default, all the tokens are valid for 12 hours.

If there is no matching user or the password is incorrect, an error message is returned with a status of `unprocessable_entity`. Example Response:
```
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/json

{
  "error": "Invalid email or password"
}
```

# Alert API documentation

## Authentication

All API expects authentication token generated via above token api in the header.


## Actions

### `POST /alert`

Creates a new alert with the specified parameters.

**Parameters:**

- `coin_symbol` (required): The symbol of the cryptocurrency to set the alert for.
- `target_price` (required): The target price for the alert.

**Example Request:**

```
POST /alert
{
  "coin_symbol": "BTC",
  "target_price": 40000
}
```

**Example Response:**

```
HTTP/1.1 201 Created
{
  "id": 1,
  "coin_symbol": "BTC",
  "target_price": 40000,
  "status": "created"
}
```

### `DELETE /alert?id=ID`

Deletes an alert with the specified ID.

**Parameters:**

- `id` (required): The ID of the alert to delete.

**Example Request:**

```
DELETE /alert?id=1
```

**Example Response:**

```
HTTP/1.1 204 No Content
```

### `GET /alert`

Retrieves a list of alerts that match the specified filter parameters.

**Parameters:**

- `status` (optional): The status of the alerts to retrieve. Defaults to all non-deleted alerts.
- `current_page` (optional): The current page of alerts to retrieve. Defaults to the first page.
- `per_page` (optional): The number of alerts to retrieve per page. Defaults to 10 alerts per page.

**Example Request:**

```
GET /alert?status=created&current_page=1&per_page=5
```

**Example Response:**

```
HTTP/1.1 200 OK
{
  "alerts": [
    {
      "id": 1,
      "coin_symbol": "BTC",
      "target_price": 40000,
      "status": "created"
    },
    {
      "id": 2,
      "coin_symbol": "ETH",
      "target_price": 3000,
      "status": "created"
    },
    {
      "id": 3,
      "coin_symbol": "DOGE",
      "target_price": 0.5,
      "status": "created"
    },
    {
      "id": 4,
      "coin_symbol": "ADA",
      "target_price": 1.5,
      "status": "created"
    },
    {
      "id": 5,
      "coin_symbol": "XRP",
      "target_price": 2,
      "status": "created"
    }
  ],
  "filter": {
    "status": "created",
    "current_page": 1,
    "per_page": 5,
    "total_pages": 1
  }
}
```


# Sequence Diagram

## when user conditon met

https://sequencediagram.org/index.html#initialData=title%20when%20user%20conditon%20met%0A%0AUser-%3EApplication%3A%20Login%0AUser-%3EApplication%3A%20Generate%20token%0AUser-%3EApplication%3A%20Create%20Alert%20for%20Coin%20X%20with%20Price%20Y%0AApplication--%3EWebsocketWorker%3A%20Enqueue%20Coin%20Subscriber%20for%20X%20with%20Price%20Y%0AWebsocketWorker-%3EBinanceWebsocketServer%3A%20Send%20Subscribe%20request%20for%5CnX%20if%20X%20is%20not%20subscribed%0ABinanceWebsocketServer--%3EWebsocketWorker%3A%20Sends%20Realtime%20update%5Cnof%20trade%20stream%20for%20X%0AWebsocketWorker-%3ESidekiqWorker%3A%20Enqueue%20Alert%20processing%20worker%20when%20condition%20met%0AWebsocketWorker-%3EBinanceWebsocketServer%3A%20Send%20Unsubscribe%20request%20if%20no%20more%20alert%20for%20that%20Coin%20X%0ASidekiqWorker-%3EUser%3A%20Sent%20Email%0ASidekiqWorker-%3EApplication%3A%20update%20alert%20that%20it%20was%20triggered%0A

```seq
User->Application: Login
User->Application: Generate token
User->Application: Create Alert for Coin X with Price Y
Application-->WebsocketWorker: Enqueue Coin Subscriber for X with Price Y
WebsocketWorker->BinanceWebsocketServer: Send Subscribe request for\nX if X is not subscribed
BinanceWebsocketServer-->WebsocketWorker: Sends Realtime update of trade stream for X
Note right of WebsocketWorker: Checks for alert condition with realtime data
WebsocketWorker->SidekiqWorker: Enqueue Alert processing worker when condition met
WebsocketWorker->BinanceWebsocketServer: Send Unsubscribe request if no more alert for that Coin X
SidekiqWorker->User: Sent Email
SidekiqWorker->Application: update alert that it was triggered
```

## when user deletes the alert in the mid

https://sequencediagram.org/index.html#initialData=title%20when%20user%20deletes%20the%20alert%20in%20the%20mid%0AUser-%3EApplication%3A%20Login%0AUser-%3EApplication%3A%20Generate%20token%0AUser-%3EApplication%3A%20Create%20Alert%20for%20Coin%20X%20with%20Price%20Y%0AApplication--%3EWebsocketWorker%3A%20Enqueue%20Coin%20Subscriber%20for%20X%20with%20Price%20Y%0AWebsocketWorker-%3EBinanceWebsocketServer%3A%20Send%20Subscribe%20request%20for%5CnX%20if%20X%20is%20not%20subscribed%0ABinanceWebsocketServer--%3EWebsocketWorker%3A%20Sends%20Realtime%20update%20of%20trade%20stream%20for%20X%0AUser-%3EApplication%3A%20Delete%20alert%0AApplication-%3EWebsocketWorker%3A%20Enqueue%20Coin%20Unsubscriber%20for%20X%0AWebsocketWorker-%3EBinanceWebsocketServer%3A%20Send%20Unsubscribe%20request%20if%20no%20more%20alert%20present%20on%20db%20for%20that%20Coin%20X%0A

```seq
User->Application: Login
User->Application: Generate token
User->Application: Create Alert for Coin X with Price Y
Application-->WebsocketWorker: Enqueue Coin Subscriber for X with Price Y
WebsocketWorker->BinanceWebsocketServer: Send Subscribe request for\nX if X is not subscribed
BinanceWebsocketServer-->WebsocketWorker: Sends Realtime update of trade stream for X
Note right of WebsocketWorker: Checks for alert condition with realtime data
User->Application: Delete alert
Application->WebsocketWorker: Enqueue Coin Unsubscriber for X
WebsocketWorker->BinanceWebsocketServer: Send Unsubscribe request if no more alert present on db for that Coin X
Note right of WebsocketWorker: RealTime trade data for X get stopped
```
