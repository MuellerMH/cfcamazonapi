/**
*
* @file  /f/dev/amazon/Connector.cfc
* @author  Manuel H. Mueller [ Onko ] mueller.m.h@gmail.com
* @description
*
*/

component output="true" displayname="Connector"  {

	property name="endpoint";
	property name="awsAccessKeyID";
	property name="awsAccessSecret";

	package function init(
		required string awsAccessKeyId,
		required string awsAccessSecret,
		string endpoint='sdb.amazonaws.com'
	)
	{
		this.endpoint=endpoint;
		this.awsAccessKeyID=awsAccessKeyID;
		this.awsAccessSecret=awsAccessSecret;
	}

	package string function createDateFormat( date dtAtt, boolean iso = false )
	{
		if(!isDate(arguments.dtAtt))
			arguments.dtAtt = NOW();

		var TimeZone = getTimeZoneInfo();
		var GDT = dateAdd('s',TimeZone.utcTotalOffset,dtAtt);
		if(iso)
			return DateFormat(GDT,'yyyy-mm-dd') & 'T' & TimeFormat(GDT,'HH:mm:ss') & 'Z';
		else 
			return DateFormat(GDT,'ddd, dd mmm yyyy') & ' ' & TimeFormat(GDT, 'HH:mm:ss') % ' GMT';

	}

	package string function createSignatur ( 
		required string data, 
		required string secretKey 
	)	
	{
		var Key = createObject('java','javax.crypto.spec.SecretKeySpec').init(toBinary(toBase64(secretKey)), 'HmacSHA256');
		var Mac = createObject('java', 'javax.crypto.Mac').getInstance('HmacSHA256');
		Mac.init(Key);
		return trim(toBase64(mac.doFinal(toBinary(toBase64(data))))); 
	}

	package string function urlEncodeNormal( required string data )
	{
		return replaceList(urlEncodedFormat(data),'%2D,%2E,%5F,%7E,+', '-,.,_,~,%20');		
	}

	package string function urlEncodeSpecial( required string data )
	{
		return replaceList(urlEncodedFormat(data),'%2D,%2E,%5F,%7E,%3D', '-,.,_,~,=');		
	}

	package string function naturalByteCode( required string oldOrder, boolean format=false, any skipEncryption)
	{
		var tmpStruct = {}
		var newOrder='';
		loop list=oldOrder index="item" delimiters="&" 
		{
			if(format)
			{
				if(listFindNoCase(skipEncryption,listFirst(item,'=')))
					tmpStruct[listFirst(item,'=')] = urlEncodeSpecial(listRest(item,'='));
				else 
					tmpStruct[listFirst(item,'=')] = urlEncodeNormal(listRest(item,'='));
			}
			else
				tmpStruct[listFirst(item,'=')] = listRest(item,'=');
		}
		var Keys = StructKeyArray(tmpStruct);
		ArraySort(Keys,'textnocase');
		loop array="#Keys#" index="key"
		{
			newOrder &= '&' & key & '=' & tmpStruct[key];
		}
		return newOrder;
	}

	package string function createSignature()
	{
		var signatureBody = 'GET#chr(10)##this.endPoint##chr(10)##argumentsCollection.uri##chr(10)#AWSAccessKeyId=#this.awsAccessKeyId#';
		var signaturBodyPart = "&#argumentsCollection.body#&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#createDateFormat(iso=true)#";
		
		if(structKeyExists(argumentsCollection,'version'))
			signaturBodyPart &= "&Version=" & argumentsCollection.version;

		signatureBody &= naturalByteCode(signaturBodyPart,true,argumentsCollection.skipEncryption);
		return trim(createSignatur(trim(signatureBody),this.awsAccessSecret));

	}

	package string function createSignaturParam()
	{
		var signaturBodyPart = "&#argumentsCollection.body#&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#createDateFormat(iso=true)#";
		
		if(structKeyExists(argumentsCollection,'version'))
			signaturBodyPart &= "&Version=" & argumentsCollection.version;
		else 
			signaturBodyPart &= "&Version=2009-04-15";

		signaturBodyPart &= "&Signature=" & createSignature( argumentsCollection=argumentsCollection);

		return naturalByteCode(signaturBodyPart) & '&AWSAccessKeyId=' & this.awsAccessKeyId;

	}

	package struct function makeRequest ( 
		required string endpoint,
		required string awsAccessKeyID,
		required string awsAccessSecret,
		uri='/',
		body='',
		requestMethod='',
		version='2009-04-15',
		skipEncryption=''
	)
	{
		this.endpoint=endpoint;
		this.awsAccessKeyID=awsAccessKeyID;
		this.awsAccessSecret=awsAccessSecret;
		
		if(requestMethod == 'no-header')
			return sendNoHeader(argumentsCollection=arguments);
		else 
			return sendHeader(argumentsCollection=arguments);
	}

	package struct function sendNoHeader()
	{		
		try 
		{
			argumentsCollection.body &= '&Version=2009-04-15';
			http method="GET" url="https://#replaceNoCase(argumentsCollection.endpoint,'https://','','ALL')##argumentsCollection.uri#" charset="UTF-8" result="result"
			{				
				loop list="#createSignaturParam(argumentsCollection=argumentsCollection)#" index="item" delimiters="&"
				{	
					httpparam type="url" name="#listFirst(item,'=')#" value="#listRest(item,'=')#";
				}
			}		
			return getResponse(result);	
		} catch( any e)
		{			
			log type="ERROR" text="getResultNodeValue: #serialize(e)#";
		}		
	}

	package struct function sendHeader()
	{		
		var body = 'AWSAccessKeyId=#this.awsAccessKeyId#&#body#';
		try 
		{
			http method="POST" url="https://#replaceNoCase(endpoint,'https://','',ALL)#" charset="UTF-8" result="result"
			{
				httpparam type="header" name="X-Amzn-Authorization" value="AWS3-HTTPS AWSAccessKeyId=#this.awsAccessKeyId#, Algorithm=HmacSHA256, Signature=#createSignature(argumentsCollection=argumentsCollection)#";
				httpparam type="header" name="Date" value="#createDateFormat(iso=false)#";
				httpparam type="header" name="Content-Type" value="application/x-www-form-urlencoded";
				httpparam type="body" value="#body#";
			}	

			return getResponse(result);		
		} catch( any e)
		{
			rethrow e;
		}

	}

	private struct function getResponse(struct result)
	{
		var ResultStruct = {}
		if(structKeyExists(result,'status_code')){
			ResultStruct['status'] = result.status_code;  
			ResultStruct['content'] = result.fileContent;
		}
		else {
			ResultStruct['status'] = 500;			
			ResultStruct['content'] = result.errordetail;
		}

		return ResultStruct;
	}

	package any function getResultNode(xml Response, string search)
	{
		try{
			return xmlSearch(Response, "//*[ local-name() = '" & search & "' ]");
		}
		catch( any e)
		{			
			log type="ERROR" text="getResultNode: #serialize(e)#";
			return false;
		}
	}

	package any function getResultNodeValue(xml Response, string search)
	{
		var tmpResult = xmlSearch(Response, "//*[ local-name() = '" & search & "' ]");
		if(isArray(tmpResult))
		{
			try{
				if(arrayLen(tmpResult)==1)
					return tmpResult[1].xmlText;
				else{
					var arrayReturn = [];
					for(i in tmpResult)
					{
						arrayAppend(arrayReturn,i.XmlText);
					}
					return arrayReturn;
				}
			}
			catch( any e)
			{
				log type="ERROR" text="getResultNodeValue: #serialize(e)#";
				return false;
			}
		}
		return false;
	}

}