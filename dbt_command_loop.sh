#!/bin/bash
# Script to run DBT commands for all the tables mentioned in table_config.yml

#table_config="table_config.yml"
table_config=$1
env=$2
failed_result=0

echo "Current working directory of the shell script dbt_command_loop.sh: " "$(pwd)"

IFS=''
if [ "$env" == "preprod" ]; then
   dbt_run_cmd="dbt run --profiles-dir ~/.dbt --project-dir . --target $env --models"
elif [ "$env" == "prod" ]; then
   dbt_run_cmd="dbt run --profiles-dir ~/.dbt/ --project-dir . --target $env --models"
else
   dbt_run_cmd="dbt run --profiles-dir ~/.dbt --project-dir . --target $env --models"
fi

cnt=1

concatenate_args()
{
  # This will concatenate all the DBT_ arguments in one line
  line_converted=$(echo ${1//: /=})
  dbt_args="${2} $line_converted"
}

create_dbt_cmd()
{
  # It will create final DBT command per table block which will then be executed directly
  final_dbt_cmd="${dbt_args} ${dbt_run_cmd} ${models}"
  echo "This is the DBT command: " "$final_dbt_cmd"
  /bin/sh -c "$final_dbt_cmd"
  if [ $? -gt 0 ]
    then
      count_failed_result "$failed_result"
  fi
}

count_failed_result()
{
  # This is to count the number of tables failed to load that day
  failed_result=$((failed_result + 1))
}

# Read each line from configuration file
while read -r line || [ -n "$line" ]; do
  # Checks if the line start with "  D" meaning all the DBT_ arguments then concatenate
  if [ "${line:0:3}" == "  D" ]
    then
      concatenate_args "$line" "$dbt_args"
      cnt=$((cnt + 1))
      new_line=1
  # This elif is to capture the model folder to run
  elif [ "${line:0:8}" == "  MODELS" ]
    then
      models=${line:10}
  # This elif will execute only if there is either a new table block started, and it will be ignored at the first line of the configuration
  elif [ "$cnt" != 1 ] && [ "$new_line" == 1 ]
    then
      create_dbt_cmd "$dbt_args" "$dbt_run_cmd" "$models" "$final_dbt_cmd"
      dbt_args=''
      new_line=0
  # Just switching off the flag new_line which will be checked again outside of while loop
  else
    new_line=2
  fi
done < "$table_config"

# New_line is just a flag used internally to know when a new table block has started
if [ $new_line == 1 ]
  then
    create_dbt_cmd "$dbt_args" "$dbt_run_cmd" "$final_dbt_cmd"
fi

# If any DBT command fails in execution, it will exit the script with error at the end so that all the commands can run and complete first.
if [ "$failed_result" -gt 0 ]
  then
    echo "$failed_result command/s has/have failed"
    exit 1
fi
