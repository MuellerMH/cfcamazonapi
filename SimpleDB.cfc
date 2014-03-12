/**
*
* @file  /f/dev/amazon/SimpleDB.cfc
* @author  Manuel H. Mueller [ Onko ] mueller.m.h@gmail.com
* @description 
*
*/

component output="true" displayname="SimpleDB" extends="Connector" {

	property name="endpoint";
	property name="awsAccessKeyID";
	property name="awsAccessSecret";
	property name="requestMethod";
	property name="version";
	
	public function init(
		required string awsAccessKeyId,
		required string awsAccessSecret,
		string endpoint='sdb.amazonaws.com'
	){
		this.awsAccessKeyId=awsAccessKeyId;
		this.awsAccessSecret=awsAccessSecret;
		this.endpoint=endpoint;
		this.requestMethod='no-header';
		this.version='2009-04-15';
		return this;
	}

	public array function ListDomains(
		numeric MaxNumberOfDomains=0,
		string NextToken=''
	)
	{
		var body = "Action=ListDomains";

		if(val(MaxNumberOfDomains))
			body &='&MaxNumberOfDomains=#trim(MaxNumberOfDomains)#';
		if(len(trim(NextToken)))
			body &='&NextToken=#NextToken#';

		var result = makeRequest ( 
			endpoint=this.endpoint,
			awsAccessKeyID=this.awsAccessKeyID, 
			awsAccessSecret=this.awsAccessSecret, 
			body=body, 
			requestMethod=this.requestMethod, 
			version=this.version		
		);
		var returnArray=[];
		var SearchResult = getResultNode(result.content,'DomainName');
		for(item in SearchResult)
		{
			ArrayAppend(returnArray,item.XmlText);
		}

		return returnArray;
			
	}

	public boolean function CreateDomain(required string DomainName )
	{
		var body = "Action=CreateDomain&DomainName=" & trim(DomainName);
		var result = makeRequest ( 
			endpoint=this.endpoint,
			awsAccessKeyID=this.awsAccessKeyID, 
			awsAccessSecret=this.awsAccessSecret, 
			body=body, 
			requestMethod=this.requestMethod, 
			version=this.version		
		);

		if(result.status == 200)
			return true;

		return false;
	}

	public boolean function DeleteDomain(required string DomainName )
	{
		var body = "Action=DeleteDomain&DomainName=" & trim(DomainName);
		var result = makeRequest ( 
			endpoint=this.endpoint,
			awsAccessKeyID=this.awsAccessKeyID, 
			awsAccessSecret=this.awsAccessSecret, 
			body=body, 
			requestMethod=this.requestMethod, 
			version=this.version		
		);
		
		if(result.status == 200)
			return true;

		return false;
	}

	public struct function DomainMetadata(required string DomainName )
	{
		var body = "Action=DomainMetadata&DomainName=" & trim(DomainName);
		var result = makeRequest ( 
			endpoint=this.endpoint,
			awsAccessKeyID=this.awsAccessKeyID, 
			awsAccessSecret=this.awsAccessSecret, 
			body=body, 
			requestMethod=this.requestMethod, 
			version=this.version		
		);

		if(result.status == 200)
			return {
				itemCount: getResultNodeValue(result.content,'ItemCount'),
				ItemNamesSizeBytes: getResultNodeValue(result.content,'ItemNamesSizeBytes'),
				AttributeNameCount: getResultNodeValue(result.content,'AttributeNameCount'),
				AttributeNamesSizeBytes: getResultNodeValue(result.content,'AttributeNamesSizeBytes'),
				AttributeValueCount: getResultNodeValue(result.content,'AttributeValueCount'),
				AttributeValuesSizeBytes: getResultNodeValue(result.content,'AttributeValuesSizeBytes'),
				Timestamp: getResultNodeValue(result.content,'Timestamp')
			}			
		
		return {};
	}

	public string function PutAttributes(required string DomainName, required string itemName, required array attr)
	{
		var body = "Action=PutAttributes&DomainName=" & trim(DomainName) & "&ItemName=" & itemName ;

		loop from="1" to="#arrayLen(attr)#" index="i"
		{
			body &= "&Attribute." & i & ".Name="  & trim(attr[i].name);
			body &= "&Attribute." & i & ".Value=" & trim(attr[i].value);
			body &= "&Attribute." & i & ".Replace=true";
		}

		var result = makeRequest ( 
			endpoint=this.endpoint,
			awsAccessKeyID=this.awsAccessKeyID, 
			awsAccessSecret=this.awsAccessSecret, 
			body=body, 
			requestMethod=this.requestMethod, 
			version=this.version		
		);		
		sleep(4);
		if(result.status == 200)
			return getResultNodeValue(result.content,'RequestId');
		return '';
	}

	public string function BatchPutAttributes(required string DomainName, required array items)
	{
		var body = "Action=BatchPutAttributes&DomainName=" & trim(DomainName);

		loop from="1" to="#arrayLen(items)#" index="i"
		{
			body &= "&Item." & i & ".ItemName="  & trim(items[i].name);
			loop from="1" to="#arrayLen(items.attr)#" index="iattr"
			{
			
				body &= "&Attribute." & iattr & ".Name="  & trim(items.attr[iattr].name);
				body &= "&Attribute." & iattr & ".Value=" & trim(items.attr[iattr].value);
				body &= "&Attribute." & iattr & ".Replace=true";
			}
		}

		var result = makeRequest ( 
			endpoint=this.endpoint,
			awsAccessKeyID=this.awsAccessKeyID, 
			awsAccessSecret=this.awsAccessSecret, 
			body=body, 
			requestMethod=this.requestMethod, 
			version=this.version		
		);		

		if(result.status == 200)
			return getResultNodeValue(result.content,'RequestId');
		return '';
	}

	public struct function GetAttributes( required string DomainName, required string ItemName, string AttributeName='', boolean ConsistentRead=false)
	{
		var body =  "Action=GetAttributes&DomainName=" & DomainName & "&ItemName=" & itemName ;
		if(len(AttributeName))
			body &= '&AttributeName=' & trim(AttributeName);
		if(ConsistentRead)
			body &= '&ConsistentRead=true';

		var result = makeRequest ( 
			endpoint=this.endpoint,
			awsAccessKeyID=this.awsAccessKeyID, 
			awsAccessSecret=this.awsAccessSecret, 
			body=body, 
			requestMethod=this.requestMethod, 
			version=this.version		
		);		

		var resultArray = getResultNode(result.content,'GetAttributesResult');

		stItem = {};
		for(item in resultArray)
		{			
			
			stItem['itemName']=ItemName;

			for(attr in item.xmlChildren)
			{
				if(attr.xmlName == 'Attribute')
					stItem[attr.name.xmlText]=attr.value.xmlText;
			}

		}
		return stItem;

	}

	public array function Select( required string QueryString, string NextToken='', boolean ConsistentRead=false)	
	{
		var body =  "Action=Select&SelectExpression=" & trim(QueryString);
		if(len(NextToken))
			body &= '&NextToken=' & trim(NextToken);
		if(ConsistentRead)
			body &= '&ConsistentRead=true';

		var result = makeRequest ( 
			endpoint=this.endpoint,
			awsAccessKeyID=this.awsAccessKeyID, 
			awsAccessSecret=this.awsAccessSecret, 
			body=body, 
			requestMethod=this.requestMethod, 
			version=this.version		
		);		

		var resultArray = getResultNode(result.content,'Item');
		var returnArray = []
		for(item in resultArray)
		{			
			stItem = {};
			stItem['itemName']=item.xmlText;

			for(attr in item.xmlChildren)
			{
				if(attr.xmlName == 'Attribute')
					stItem[attr.name.xmlText]=attr.value.xmlText;
				if(attr.xmlName == 'Name')
					stItem['itemName']=attr.xmlText;
			}
			ArrayAppend(returnArray,stItem);
		}
		return returnArray;
	}

	public boolean function DeleteAttributes(required DomainName, string ItemName, array attr=[])
	{
		var body = "Action=DeleteAttributes&DomainName=" & trim(DomainName) & "&ItemName=" & trim(ItemName) ;

		loop from="1" to="#arrayLen(attr)#" index="i"
		{
			body &= "&Attribute." & i & ".Name="  & trim(attr[i].name);
			body &= "&Attribute." & i & ".Value=" & trim(attr[i].value);
			body &= "&Attribute." & i & ".Replace=true";
		}
		var result = makeRequest ( 
			endpoint=this.endpoint,
			awsAccessKeyID=this.awsAccessKeyID, 
			awsAccessSecret=this.awsAccessSecret, 
			body=body, 
			requestMethod=this.requestMethod, 
			version=this.version		
		);
		
		if(result.status == 200)
			return true;

		return false;
	}

	public boolean function BatchDeleteAttributes(required string DomainName, required array items)
	{
		var body = "Action=BatchDeleteAttributes&DomainName=" & trim(DomainName);

		loop from="1" to="#arrayLen(items)#" index="i"
		{
			body &= "&Item." & i & ".ItemName="  & trim(items[i].name);
			loop from="1" to="#arrayLen(items.attr)#" index="iattr"
			{
			
				body &= "&Attribute." & iattr & ".Name="  & trim(items.attr[iattr].name);
				body &= "&Attribute." & iattr & ".Value=" & trim(items.attr[iattr].value);
				body &= "&Attribute." & iattr & ".Replace=true";
			}
		}

		var result = makeRequest ( 
			endpoint=this.endpoint,
			awsAccessKeyID=this.awsAccessKeyID, 
			awsAccessSecret=this.awsAccessSecret, 
			body=body, 
			requestMethod=this.requestMethod, 
			version=this.version		
		);		

		if(result.status == 200)
			return true;

		return false;
	}

}