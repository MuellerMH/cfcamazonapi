/**
*
* @file  /f/dev/amazon/SES.cfc
* @author  Manuel H. Mueller [ Onko ] mueller.m.h@gmail.com
* @description
*
*/

component output="false" displayname="SES" extends="Connector"  {

	public function init( required string awsAccessKeyId, required string awsAccessSecret, string endpoint='email-smtp.eu-west-1.amazonaws.com'){
		this.endpoint = endpoint;
		this.awsAccessKeyId = awsAccessKeyId;
		this.awsAccessSecret = awsAccessSecret;
		return this;
	}

	public boolean function sendMail(required string to, required string from, required string subject, string plain='', string html='')
	{
		var body = "Action=SendEmail";
		var count = 1;
		if (listLen(to,',' )){
			loop list="#to#" index="listItem" {
				body &= '&Destination.ToAddresses.member.' & count & '=' & trim(listItem);
				count++;
			}
		}	
		else
			body &= '&Destination.ToAddresses.member.1=' & trim(to);
		
		if(len(html))
			body &= '&Message.Body.Html.Data=' & trim(html);
		else if(len(plain))		
			body &= '&Message.Body.Text.Data=' & trim(plain);
		else 
			body &= '&Message.Body.Text.Data=';

		body &= "&Message.Subject.Data=#trim(subject)#&Source=#trim(from)#";


		var result = makeRequest ( 
			endpoint=this.endpoint,
			awsAccessKeyID=this.awsAccessKeyId, 
			awsAccessSecret=this.awsAccessSecret, 
			body=body,
			requestMethod='no-header'
		);

		if(result.status == 200)
			return true;

		return false;
	}
}