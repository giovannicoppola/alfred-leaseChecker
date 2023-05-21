
#LEASE CHECKER
#Light rain, mist 🌦   🌡️+60°F (feels +60°F, 93%) 🌬️↙6mph 🌑&m Sat May 20 11:20:32 2023
#W20Q2 – 140 ➡️ 224 – 9 ❇️ 356


# Lease details
start_date=$LEASE_START_DATE     
lease_length=$LEASE_DURATION
allowed_miles_per_year=$MILEAGE

overage_rate=$OVERAGE_CHARGE

# Validate start date format
if ! [[ $start_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then

cat << EOB
{"items": [

	{
		"title": "🚨 Error: Invalid start date format.",
		"subtitle": "Check the date in Workflow Configuration. Please use the format YYYY-MM-DD!"
		}
	
]}
EOB
exit 1
fi


# Validate input value
if [[ ! $1 =~ ^[0-9]+$ ]]; then
cat << EOB
{"items": [

	{
		"title": "🚨 Error: Invalid value!",
		"subtitle": "Enter numbers only"
		}
	

	

]}
EOB
exit 1
fi


# Current date
current_date=$(date "+%Y-%m-%d")

# Convert start date to Unix timestamp
start_timestamp=$(date -j -f "%Y-%m-%d" "$start_date" "+%s" 2>/dev/null) || {
cat << EOB
{"items": [

	{
		"title": "🚨 Error: Invalid start date.",
		"subtitle": "Check the date in Workflow Configuration"
	}

]}
EOB
exit 1
}

# Convert current date to Unix timestamp
current_timestamp=$(date -j -f "%Y-%m-%d" "$current_date" "+%s")

# Calculate the number of days elapsed
days_elapsed=$(( (current_timestamp - start_timestamp) / (24 * 60 * 60) ))

# Calculate the remaining lease duration in days
end_timestamp=$(date -j -v "+${lease_length}m" -f "%Y-%m-%d" "$start_date" "+%s")
remaining_days=$(( (end_timestamp - current_timestamp) / (24 * 60 * 60) ))

# Calculate the allowed miles for the remaining lease duration
allowed_miles_remaining=$(( remaining_days * allowed_miles_per_year / 365 ))

# Calculate the expected number of miles at the end of the lease
expected_miles=$(( $1 + allowed_miles_remaining ))
LC_ALL=en_US.UTF-8
expected_miles_formatted=$(printf "%'d" "$expected_miles")


# Calculate the total allowed miles for the entire lease duration
total_allowed_miles=$(( lease_length * allowed_miles_per_year / 12 ))
total_allowed_miles_formatted=$(printf "%'d" "$total_allowed_miles")

# Calculate the amount owed if over the mileage allowance
if (( $(echo "$expected_miles > $total_allowed_miles" | bc -l) )); then
    overage_miles=$(( expected_miles - total_allowed_miles ))
    amount_owed=$(echo "$overage_miles * $overage_rate" | bc)
    # Format variables with thousand separator
    
	overage_miles_formatted=$(printf "%'d" "$overage_miles")
    amount_owed_formatted=$(printf "%'0.2f" "$amount_owed")

    msgText="You are expected to have a $overage_miles_formatted mi overage and to owe \$$amount_owed_formatted 😬"
else
    amount_owed=0
    msgText="You are on track to stay within the allowed miles ($expected_miles_formatted/$total_allowed_miles_formatted) 😅"
fi

subText="Expected miles: $expected_miles_formatted. Days remaining until the end of the lease: $remaining_days"
cat << EOB
{"items": [

	{
		"title": "$msgText",
		"subtitle": "$subText",
		"arg": "$msgText\n$subText"
		
	}
	

]}
EOB
