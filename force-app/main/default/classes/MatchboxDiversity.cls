public with sharing class MatchboxDiversity{

    /**
     * Returns a set of records that is as diverse in regards to the field set input
     *
     * @param  Map<Id,SObject> pSObjectMap      A map of sobject to evaluate
     * @param  List<String> pFieldSet           A list of fields to use for measuring diversity
     * @param  Integer pGroupSize               The number of records to return
     * @return Map<Id,SObject>                  The subset of diverse records
     */
    public static Map<Id,SObject> getDiverseGroup(
        Map<Id,SObject> pSObjectMap,
        List<String> pFieldSet,
        Integer pGroupSize
    ){
    
        Map<Id,SObject> selectedSObjectMap = new Map<Id,SObject>();
        Map<String,Map<String,Integer>> propertyCountMap = new Map<String,Map<String,Integer>>();
        
        for( String s_i : pFieldSet ){
        
            if( propertyCountMap.get(s_i) == null ){
                propertyCountMap.put(
                    s_i,
                    new Map<String,Integer>()
                );
            }
        }
        
        Double highestScore = 0;
        Id highestScoreObjectId = null;
        
        
        for( Integer i=0; i<pGroupSize; i++ ){
        
            highestScore = 0;
            highestScoreObjectId = null;
            
            for( SObject so_i : pSObjectMap.values() ){
            
                if( !selectedSObjectMap.containsKey( (String)so_i.get('Id') ) ){
                
                    Double userScore = 0;
                    
                    for( String s_i : pFieldSet ){
                    
                        String userPropValue = (String)so_i.get( s_i );
                        
                        if( userPropValue == null ){
                        
                            userPropValue = 'null';
                        }
                        
                        if( propertyCountMap.get( s_i ).get( userPropValue ) == null ){
                            
                            userScore++;
                        }else{
                        
                            Double v = propertyCountMap.get( s_i ).get( userPropValue ) + 1;
                            v = 1-Math.log10( v );
                            userScore += v;
                        }
                    }
                    
                    if( userScore > highestScore ){
                    
                        highestScore = userScore;
                        highestScoreObjectId = so_i.Id;
                    }
                }
            }
            
            SObject selectedSObject = pSObjectMap.get( highestScoreObjectId );
            
            selectedSObjectMap.put( 
                (String)selectedSObject.get('Id'),
                selectedSObject
            );
            
            for( String s_i : pFieldSet ){
                
                String userPropValue = (String)selectedSObject.get( s_i );
                
                if( userPropValue == null ){
                    
                    userPropValue = 'null';
                }
                
                if( propertyCountMap.get( s_i ).get( userPropValue ) == null ){
                    
                    propertyCountMap.get( s_i ).put( 
                        userPropValue,
                        0
                    );
                    
                }
                propertyCountMap.get( s_i ).put( 
                    userPropValue,
                    propertyCountMap.get( s_i ).get( userPropValue )+1
                );
            }
        }
        
        System.debug( propertyCountMap );
        
        
        return selectedSObjectMap;
    }



    /**
     * Finds the diverse users of resource preferences for each resource in a resource category if category is set to base on diversity
     *
     * @param  Resource_Category__c pResourceCategory       A resource category to evaluate diversty
     * @return Map<Id,Resource_Preference__c>               The subset of diverse resource preferences marked as preferred by resource owner
     */
    public static Map<Id,Resource_Preference__c> assignDiverseResourcePreferences(
        Resource_Category__c pResourceCategory
    ){

        Map<Id,Resource_Preference__c> preferredResourcePreferenceMap = new Map<Id,Resource_Preference__c>();

        if( 
                pResourceCategory.Select_Preferred_Based_On_Diversity__c
            &&  pResourceCategory.Diversity_Fields__c != null
        ){

            Map<Id,Resource__c> resourceMap = new Map<Id,Resource__c>([
                SELECT
                    Id,
                    Number_of_Slots__c,
                    (
                        SELECT
                            Id,
                            OwnerId,
                            Preferred_By_Resource_Owner__c
                        FROM
                            Resource_Preferences__r
                    )
                FROM
                    Resource__c
                WHERE
                    Resource_Category__c = :pResourceCategory.Id
            ]);

            // compile list of diversity fields and dynamic query user object

            String q = 'SELECT Id,' + String.escapeSingleQuotes(pResourceCategory.Diversity_Fields__c.replaceAll(';',','));
            q += ' FROM USER WHERE Id IN (SELECT OwnerId FROM Resource_Preference__c WHERE Resource__r.Resource_Category__c = \'';
            q += String.escapeSingleQuotes(pResourceCategory.Id) + '\')';

            List<User> userList = (List<User>)Database.query( q );

            Map<Id,User> userMap = new Map<Id,User>();

            for( User u_i : userList ){

                userMap.put( 
                    u_i.Id,
                    u_i
                );
            }


            
            // For each resource
            //  Get all users from resource preferences
            //  run diversity algorithm if more users than slots
            //  else just mark all users as preferred
            for( Resource__c r_i : resourceMap.values() ){
                
                Map<Id,User> resourceUserMap = new Map<Id,User>();

                for( Resource_Preference__c rp_i :  r_i.Resource_Preferences__r ){

                    resourceUserMap.put( 
                        rp_i.OwnerId,
                        userMap.get(rp_i.OwnerId)
                    );
                }

                Map<Id,User> selectedUserMap = new Map<Id,User>();

                if( resourceUserMap.values().size() > r_i.Number_of_Slots__c ){

                    Map<Id,SObject> sobjectMap = MatchboxDiversity.getDiverseGroup(
                        resourceUserMap,
                        pResourceCategory.Diversity_Fields__c.split(';'),
                        (Integer)r_i.Number_of_Slots__c
                    );

                    List<User> uList = (List<User>)sobjectMap.values();

                    for( User u_i : uList ){

                        selectedUserMap.put(
                            u_i.Id,
                            u_i
                        );
                    }

                }else{
                    selectedUserMap.putAll( resourceUserMap );
                }

                for( Resource_Preference__c rp_i :  r_i.Resource_Preferences__r ){

                    if( selectedUserMap.containsKey( rp_i.OwnerId ) ){

                        rp_i.Preferred_By_Resource_Owner__c = true;

                        preferredResourcePreferenceMap.put(
                            rp_i.Id,
                            rp_i
                        );
                    }
                }
            }
        }

        return preferredResourcePreferenceMap;
    }
}