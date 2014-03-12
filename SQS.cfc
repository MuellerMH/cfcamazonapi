/**
*
* @file  /f/dev/amazon/SQS.cfc
* @author  Manuel H. Mueller [ Onko ] mueller.m.h@gmail.com
* @description
*
*/

component output="false" displayname="" extends="Connector"  {

	public function init( required string awsAccessKeyID, required string awsAccessSecret, string endpoint='sqs.eu-west-1.amazonaws.com'){
		this.endpoint = endpoint;
		this.awsAccessKeyID = awsAccessKeyID;
		this.awsAccessSecret = awsAccessSecret;
		this.endpoint=endpoint;
		this.requestMethod='no-header';
		this.version='2011-10-01';

		return this;
	}

	public function CreateQueue(String queueName, array attributes)
	{
		var body = "Action=CreateQueue";
		body &= "QueueName=" & queueName;

		for(var i = 1; i<len(attributes); i++)
		{			
			body &= "&Attribute.#i#.Name=" & attributes[i].name;
			body &= "&Attribute.#i#.Value=" & attributes[i].value;			
		}

		var result = makeRequest ( 
			endpoint=this.endpoint,
			awsAccessKeyID=this.awsAccessKeyID, 
			awsAccessSecret=this.awsAccessSecret, 
			body=body,
			requestMethod = this.requestMethod,
			version = this.version
		);

		if(result.status == 200)
			return getResultNodeValue(result.content, "QueueUrl");

		return false;
	}

	public function ListQueue(String queueNamePrefix)
	{
		var body = "Action=ListQueues";
		body &= "QueueNamePrefix=" & queueNamePrefix;

		var result = makeRequest ( 
			endpoint=this.endpoint,
			awsAccessKeyID=this.awsAccessKeyID, 
			awsAccessSecret=this.awsAccessSecret, 
			body=body,
			requestMethod = this.requestMethod,
			version = this.version
		);

		if(result.status == 200)
			return getResultNodeValue(result.content, "ListQueuesResult");

			//TODO: perepair Result
			//--- add Result 

		return false;
	}

	public function DeleteQueue()
	{

	}

	private function GetQueueUrl(String queue)
	{
		var body = "Action=GetQueueUrl&QueueName=" & trim(queue);

		var result = makeRequest ( 
			endpoint=this.endpoint,
			awsAccessKeyID=this.awsAccessKeyID, 
			awsAccessSecret=this.awsAccessSecret, 
			body=body,
			requestMethod = this.requestMethod,
			version = this.version
		);

		if(result.status == 200)
		{
			if(isXML(result.content))
			{
				var resSt = xmlparse(result.content);
				return replacenocase(resSt.GetQueueUrlResponse.GetQueueUrlResult.1.QueueUrl.XmlText,'https://' & this.endPoint,'','all');				

			}

		} 
		else return false;
			dump(var="#result#",label="35|SQS.cfc",format="html",abort=true);


	}


	public function ReceiveMessage( String queue, limit)
	{
		var body = "Action=ReceiveMessage";

		if(limit)
		{
			body &= "&MaxNumberOfMessages="& trim(limit);
		}

		var result = makeRequest ( 
			endpoint=this.endpoint,
			uri=GetQueueUrl(queue),
			awsAccessKeyID=this.awsAccessKeyID, 
			awsAccessSecret=this.awsAccessSecret, 
			body=body,
			requestMethod = this.requestMethod,
			version = this.version
		);

		if(result.status == 200)
			return true;

		return false;
	}

	public function SendMessage(String queue, String message )
	{		

		var body = "Action=SendMessage&MessageBody=" & trim(message);
		var result = makeRequest ( 
			endpoint=this.endpoint,
			uri=GetQueueUrl(queue),
			awsAccessKeyID=this.awsAccessKeyID, 
			awsAccessSecret=this.awsAccessSecret, 
			body=body,
			requestMethod = this.requestMethod,
			version = this.version
		);
		var messageId = 0;
		if(isXML(result.content))
		{
			var resSt = xmlparse(result.content);				
			messageId = getResultNodeValue(result.content,'MessageId');
		}


		if(result.status == 200)
			return {
				messageId: messageId,
				status: result.status
			}

		return result;
	}


}