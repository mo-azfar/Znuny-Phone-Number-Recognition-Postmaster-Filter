# Znuny Phone Number Recognition Postmaster Filter
- Recognize phone number in mail body and set customer user based on registered phone number
- Based on Znuny 7.0.x

Situation:

- External system send an email to Znuny that contains phone number.
- Ticket should be created with customer user profile that related to the phone number value.

1. Deploy the files to their location, set the correct permissions and deploy config.

2. Update the correct 'mail address from' Admin > PostMaster::PreFilterModule###4-PhoneNumberRecognition
	*this is to only campture an email from specific sytem.
	
		FromAddressRegExp => external-system@example.com
	
3. External system should send an email with Body: 

		PhoneNumber: 0123456789
		
4. Make sure customer user profile field Mobile has a value in it.		
