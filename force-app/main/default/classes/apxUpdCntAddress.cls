//your class must implement the Database.Batchable interface
global class UpdateContactAddresses implements 
    Database.Batchable<sObject>, Database.Stateful {
    
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    //to collect the records or objects to be passed to the interface method execute for processing
    //This method is called once at the beginning of a Batch Apex job
    //It returns the list of records to be processed by calling Database.getQueryLocator with a SOQL query.
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ID, BillingStreet, BillingCity, BillingState, ' +
            'BillingPostalCode, (SELECT ID, MailingStreet, MailingCity, ' +
            'MailingState, MailingPostalCode FROM Contacts) FROM Account ' + 
            'Where BillingCountry = \'USA\''
        );
    }
    //Performs the actual processing for each “batch” of data passed to the method. 
    //This method takes a reference to the Database.BatchableContext object
    //and batch of 200 account records is passed in the second parameter 
    global void execute(Database.BatchableContext bc, List<Account> scope){
        // process each batch of records
        List<Contact> contacts = new List<Contact>();
        for (Account account : scope) {
            for (Contact contact : account.contacts) {
                contact.MailingStreet = account.BillingStreet;
                contact.MailingCity = account.BillingCity;
                contact.MailingState = account.BillingState;
                contact.MailingPostalCode = account.BillingPostalCode;
                // add contact to list to be updated
                contacts.add(contact);
                // increment the instance member counter
                recordsProcessed = recordsProcessed + 1;
            }
        }
        update contacts;
    }   
    //to execute post-processing operations (for example, sending an email) 
    //and is called once after all batches are processed. 
    //performs a query on the AsyncApexJob object (a table that lists information about batch jobs)
    global void finish(Database.BatchableContext bc){
        System.debug(recordsProcessed + ' records processed. Shazam!');
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()];
        // call some utility to send email
        EmailUtils.sendMessage(job, recordsProcessed);
    }    
}
