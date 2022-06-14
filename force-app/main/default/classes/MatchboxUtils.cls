global with sharing class MatchboxUtils {
    
    /**
     * Runs the matching mechanism batch process
     *
     * @param  List<Id> pResourceCollectionIdList       A collection to batch process. Invoked primarily in Flows.
     * @return List<Boolean>                            returns true if the collection was processed
     */
    @InvocableMethod(label='Run Matching Mechanism')
    global static List<Boolean> runMatchingBatch(
        List<Id> pResourceCollectionIdList
    ){
        if( pResourceCollectionIdList == null || pResourceCollectionIdList.size() < 1 ){
            return new List<Boolean>{false};
        }
        
        Id resourceCollectionId = pResourceCollectionIdList[0];
        
        List<Resource_Collection__c> resourceCollection = new List<Resource_Collection__c>( [
            SELECT
                Id
            FROM
                Resource_Collection__c
            WHERE
                    Matching_Status__c = 'Not Started'
                AND Id = :resourceCollectionId
        ] );
        
        if( !resourceCollection.isEmpty() ){
            
            Database.executeBatch( new MatchboxResourceMatchingBatch( resourceCollectionId ) ); 
            return new List<Boolean>{true};  
        }
        
        return new List<Boolean>{false};
    }
    

    /**
     * Shuffles a list of user for random prioritization
     *
     * @param  List<User> pUserList       A list of users to shuffle
     * @return List<User>                 A shuffled list of users
     */
    public static List<User> shuffle(
        List<User> pUserList
    ){
    
        Integer currentIndex = pUserList.size();
        User user;
        Integer randomIndex;
                
        // While there remain elements to shuffle...
        while (0 != currentIndex) {
        
            // Pick a remaining element...
            randomIndex = integer.valueOf(Math.floor(Math.random() * currentIndex));
            currentIndex -= 1;
            
            // And swap it with the current element.
            user = pUserList[currentIndex];
            pUserList[currentIndex] = pUserList[randomIndex];
            pUserList[randomIndex] = user;
        }
        
        return pUserList;
    }


    /**
     * Determins which resource preferences should be matched
     *
     * @param  Resource_Category__c pResourceCategory   A category to determine matched resource preferences.
     * @param  List<User> pUserPriorityList             A prioritized list of users. This is useful in apex tests.
     * @return Map<Id,Resource_Preference__c>           The map of resource preferences that are matched
     */
    public static Map<Id,Resource_Preference__c> assignMatchesForResourceCategory(
        Resource_Category__c pResourceCategory,
        List<User> pUserPriorityList
    ){
        // Map to keep track of current user to resource matching
        Map<Id,List<User>> resourceToUserListMap = new Map<Id,List<User>>();
    
        // Resource Preferences Map
        Map<Id,Resource_Preference__c> resourcePreferenceMap = new Map<Id,Resource_Preference__c>(
            [
                SELECT
                    Id,
                    Order__c,
                    OwnerId,
                    Resource__c,
                    Matched__c,
                    Preferred_By_Resource_Owner__c
                FROM
                    Resource_Preference__c
                WHERE
                    Resource__r.Resource_Category__c = :pResourceCategory.Id
                ORDER BY Order__c ASC
            ]
        );
        
        // Resource Map
        Map<Id, Resource__c> resourceMap = new Map<Id,Resource__c>(
            [
                SELECT
                    Id,
                    Number_of_Slots__c
                FROM
                    Resource__c
                WHERE
                    Resource_Category__c = :pResourceCategory.Id
            ]
        );
        
        // User Map
        Map<Id,User> userMap = new Map<Id,User>(
            [
                SELECT
                    Id,
                    Username
                FROM
                    User
                WHERE
                    Id IN (
                        SELECT
                            OwnerId
                        FROM
                            Resource_Preference__c
                        WHERE
                            Resource__r.Resource_Category__c = :pResourceCategory.Id
                    )
            ]
        );
        
        // Keep track of the current index of user prefeence
        Map<Id,Integer> userCurrentPreferenceIndex = new Map<Id,Integer>();
        
        for( User u_i : userMap.values() ){
        
            userCurrentPreferenceIndex.put(
                u_i.Id,
                0
            );
        }
        
        // Keep track after each iteration which users could not be matched to their most preferred resource
        // Will assume all users are unmatched to start
        List<User> unmatchedUserList = new List<User>();
        unmatchedUserList.addAll( MatchboxUtils.shuffle( userMap.values() ) );
        
        // If a priority list of users was already established, use that
        // It's useful in cases were priority is established by some other mechanism
        // Also useful for testing without randmness
        List<User> userPriorityList = new List<User>();
        
        if( pUserPriorityList != null ){
        
            userPriorityList = pUserPriorityList;
        
        } else {
        
            userPriorityList.addAll( unmatchedUserList );
        }
        

        //Create a map of user -> preference order -> resource for easy access
        Map<Id, Map<Integer,Resource_Preference__c>> userOrderResourceMap = new Map<Id, Map<Integer,Resource_Preference__c>>();
        
        for( Resource_Preference__c rp_i : resourcePreferenceMap.values() ){
            
            if( userOrderResourceMap.get( rp_i.OwnerId ) == null ){
                
                userOrderResourceMap.put(
                    rp_i.OwnerId,
                    new Map<Integer,Resource_Preference__c>()
                );
            }
            
            userOrderResourceMap.get( rp_i.OwnerId ).put(
                (Integer)rp_i.Order__c,
                rp_i
            );
        }


        // Create a map of resource -> list of users wanting that resource in each iteration
        for( Resource__c r_i : resourceMap.values() ){
        
            if( resourceToUserListMap.get( r_i.Id ) == null ){
            
                resourceToUserListMap.put(
                    r_i.Id,
                    new List<User>()
                );
            }
        }
        
        // Keep track of any users that can no long be matched so we stop trying to match
        Set<Id> unmatchableUserSet = new Set<Id>();
        
        // keep running until we have no more folks that can be matched
        while( unmatchedUserList.size() > 0 ){
        
            // move user to next preferred resource
            // delete from resource map
            for( User u_i : unmatchedUserList ){
                
                Integer currentIndex = userCurrentPreferenceIndex.get( u_i.Id );
                currentIndex++;
                userCurrentPreferenceIndex.put( u_i.Id, currentIndex );
                
                Resource_Preference__c selectedResourcePreference = userOrderResourceMap.get( u_i.Id ).get( currentIndex );
                
                
                for( Id resourceId : resourceToUserListMap.keySet() ){
                    
                    for( Integer i=0; i<resourceToUserListMap.get( resourceId ).size(); i++ ){
                    
                        if( resourceToUserListMap.get( resourceId )[i].Id == u_i.Id ){
                            
                            resourceToUserListMap.get( resourceId ).remove( i );
                        }
                    }
                }
                
                if( selectedResourcePreference != null ){
                
                    resourceToUserListMap.get( selectedResourcePreference.Resource__c ).add( u_i );
                }
            }
            
            for( Id resourceId : resourceToUserListMap.keySet() ){
                    
                for( Integer i=0; i<resourceToUserListMap.get( resourceId ).size(); i++ ){
                
                    if( unmatchableUserSet.contains( resourceToUserListMap.get( resourceId )[i].Id )){
                        
                        resourceToUserListMap.get( resourceId ).remove( i );
                    }
                }
            }
            
            
            // Recalculate unmatched list
            unmatchedUserList.clear();
            
            
            // resource__c.Id => number to compare to open slots
            Map<Id,Integer> resourceCurrentSlotMap = new Map<Id,Integer>();
            
            for(Resource__c r_i : resourceMap.values() ){
                
                resourceCurrentSlotMap.put(
                    r_i.Id,
                    0
                );
            }
            
            
            // Get user current preference
            // if no resource exists, add user to unmatchable
            // if current pref, check if available slots on resource
            // run first for resources that have preferences to users
            // run a second time for resource that do not have preferences to users
            // if no available slots, users goes to unmatched list
            // if available slots, users stays with current preference
            for(Integer i=0; i<2; i++){

                for( User u_i : userPriorityList ){

                    
                    Resource_Preference__c currentPref = userOrderResourceMap.get( u_i.Id ).get( userCurrentPreferenceIndex.get( u_i.Id ) );
                
                    if( currentPref != null ){

                        if( i==0 && currentPref.Preferred_By_Resource_Owner__c ){

                            if( (resourceCurrentSlotMap.get( currentPref.Resource__c ) >= (resourceMap.get( currentPref.Resource__c ).Number_of_Slots__c)) ){
                    
                                unmatchedUserList.add( u_i );
                            }
                    
                            resourceCurrentSlotMap.put( 
                                currentPref.Resource__c,
                                resourceCurrentSlotMap.get( currentPref.Resource__c ) + 1
                            );
                        }

                        if( i==1 && !currentPref.Preferred_By_Resource_Owner__c ){

                            if( (resourceCurrentSlotMap.get( currentPref.Resource__c ) >= (resourceMap.get( currentPref.Resource__c ).Number_of_Slots__c)) ){
                    
                                unmatchedUserList.add( u_i );
                            }
                    
                            resourceCurrentSlotMap.put( 
                                currentPref.Resource__c,
                                resourceCurrentSlotMap.get( currentPref.Resource__c ) + 1
                            );
                        }
                        
                    }else{
                    
                        unmatchableUserSet.add( u_i.Id );
                    }
                }
            }
        }

        
        // Create the map of resource preferences to return as matches
        Map<Id, Resource_Preference__c> selectResourcePreferenceMap = new Map<Id, Resource_Preference__c>();
        
        for( Id resourceId : resourceToUserListMap.keySet() ){
        
            for( User u_i : resourceToUserListMap.get( resourceId ) ){
            
                for( Resource_Preference__c rp_i : resourcePreferenceMap.values() ){
                
                    if( rp_i.OwnerId == u_i.Id && rp_i.Resource__c == resourceId ){
                    
                        rp_i.Matched__c = true;
                        
                        selectResourcePreferenceMap.put(
                            rp_i.Id,
                            rp_i
                        );
                    }
                }
            }
        }
        
        return selectResourcePreferenceMap;
    }
}