#!/bin/bash
PSQL="psql -X -U freecodecamp -d salon --no-align --tuples-only -c"
echo -e "\n~~~~~ MY SALON ~~~~~\n"

MAIN_MENU() {
  echo -e "Welcome to My Salon, how can I help you?\n"
  LIST_OF_SERVICES=$($PSQL "SELECT * FROM services  ORDER BY service_id")
  while IFS='|' read SERVICE_ID NAME
  do
    echo "$SERVICE_ID) $NAME"
  done <<< "$LIST_OF_SERVICES"

  # loop until user provide a valid service id
  while true
  do
    read SERVICE_ID_SELECTED

    # must be a valid number
    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]];
    then
      echo -e "\nThat is not a valid number. Please choice a valid service id:"
      # re-display services
      while IFS='|' read SERVICE_ID NAME; do echo "$SERVICE_ID) $NAME"; done <<< "$LIST_OF_SERVICES"
      continue
    fi

    # must exist in DB
    SERVICE_EXISTS=$($PSQL "SELECT service_id FROM services WHERE service_id = $SERVICE_ID_SELECTED")
    if [[ -z $SERVICE_EXISTS ]]; then
      echo -e "\nI could not find that service. What would you like today?"
      # re-display services
      while IFS='|' read SERVICE_ID NAME; do echo "$SERVICE_ID) $NAME"; done <<< "$LIST_OF_SERVICES"
      continue
    fi

    # valid selection -> break loop
    break
  done
  
  # get customer info
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
  # if not found
  if [[ -z $CUSTOMER_ID ]];
  then
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME
    # insert new customer to db
    INSERT_CUSTOMER=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
    # get customer id
     CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
  fi

  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
  
  # trim whitespace that can come from psql
  SERVICE_NAME=$(echo "$SERVICE_NAME" | sed -E 's/^ *| *$//g')
  CUSTOMER_NAME=$(echo "$CUSTOMER_NAME" | sed -E 's/^ *| *$//g')

  echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
  read SERVICE_TIME
  # book a new appointment
  INSERT_APPOINTMENT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
  echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
}
MAIN_MENU

