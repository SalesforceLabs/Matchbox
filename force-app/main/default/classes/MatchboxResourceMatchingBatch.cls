global with sharing class MatchboxResourceMatchingBatch implements Database.Batchable<sObject>{

    global final String resourceCollectionId;
    global Boolean      hasError = false;

    /**
     * Batch process for iterating through categories of a collection and matching users to resources
     *
     * @param  Id pResourceCollectionId             A resource collection to run batch process on
     */
    global MatchboxResourceMatchingBatch( Id pResourceCollectionId ){
        
        resourceCollectionId = pResourceCollectionId;
        
        Database.update( 
            new Resource_Collection__c(
                Id = resourceCollectionId,
                Matching_Status__c = 'In Progress'
            )
        );
    }
    
   

    /**
     * Start method queries for categories within the collection
     *
     * @param  Database.BatchableContext BC       A batchable context
     * @return Database.QueryLocator              A query locator
     */
    global Database.QueryLocator start(
        Database.BatchableContext BC
    ){
        return Database.getQueryLocator(
            [
                SELECT
                    Id,
                    Select_Preferred_Based_On_Diversity__c,
                    Diversity_Fields__c
                FROM
                    Resource_Category__c
                WHERE
                    Resource_Collection__c = :resourceCollectionId
            ]
        );
    }

    /**
     * Execute method determines diverse groups for each category and matches per resource
     *
     * @param  Database.BatchableContext BC       A batchable context
     * @param  List<sObject> scope                A list of records to process
     * @return void
     */
    global void execute(
        Database.BatchableContext BC, 
        List<sObject> scope
    ){
        try {
            
            // Get list of resource preferences that should be marked as preferred based on diversity
            List<Resource_Category__c> resourceCategoryList = (List<Resource_Category__c>)scope;
            
            Map<Id,Resource_Preference__c> diverseResourcePreferenceMap = new Map<Id,Resource_Preference__c>();
            
            for( Resource_Category__c rc_i : resourceCategoryList){
            
                diverseResourcePreferenceMap.putAll(
                    MatchboxDiversity.assignDiverseResourcePreferences(
                        rc_i
                    )
                );
            }

            if( !diverseResourcePreferenceMap.isEmpty() ){
                
                Database.update( diverseResourcePreferenceMap.values() );
            }
            

            // Get list of reources preferences that should be matched to resource
            Map<Id,Resource_Preference__c> resourcePreferenceMap = new Map<Id,Resource_Preference__c>();

            for( Resource_Category__c rc_i : resourceCategoryList){
            
                resourcePreferenceMap.putAll(
                    MatchboxUtils.assignMatchesForResourceCategory(
                        rc_i,
                        null
                    )
                );
            }
            
            if( !resourcePreferenceMap.isEmpty() ){
                
                Database.update( resourcePreferenceMap.values() );
            }

        } catch (Exception e) {
            
            // If we get an error, mark collection with status of error
            this.hasError = true;
            Database.update( 
                new Resource_Collection__c(
                    Id = resourceCollectionId,
                    Matching_Status__c = 'Error'
                )
            );
        }
    }

   global void finish(Database.BatchableContext BC){
       
        // If we didn't get an error, mark collection status as completed
        if( !this.hasError){
            Database.update( 
                new Resource_Collection__c(
                    Id = resourceCollectionId,
                    Matching_Status__c = 'Completed'
                )
            );
        }
    }
}