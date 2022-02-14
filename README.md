# Test Driven Development with FastAPI and Docker

![Continuous Integration and Delivery](https://github.com/apoclyps/test-driven-development-with-fastapi-and-docker/workflows/Continuous%20Integration%20and%20Delivery/badge.svg?branch=main)

### How to Deploy the API

```bash
heroku create
heroku container:login

export $HEROKU_DEPLOYMENT="tdd-fastapi-with-docker"
heroku addons:create heroku-postgresql:hobby-dev --app $HEROKU_DEPLOYMENT
```

```bash
make deploy
```

This will run the following targets in order:

```bash
make artifact
make package
make publish
make release
make migrate
```

### Example Request

Running the following command will add a summary to the database and return the response from the POST request.

```bash
http --json POST https://tdd-fastapi-with-docker.herokuapp.com/summaries/ url=https://testdriven.io
```

## Documentation

Running the following command will open the OpenAPI documentation for the API:

```bash
make docs
```
