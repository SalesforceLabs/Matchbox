public with sharing class MatchboxGetUserPreferences {

    /**
     * Gets list of users current preferences for a list of resources. Primarily used in Flows.
     *
     * @param  List<List<Resource__c>> pResourceList        A list of resources to get current users preferences for
     * @return List<List<Resource_Preference__c>>           Returns the current list of user preferences
     */
    @InvocableMethod
    public static List<List<Resource_Preference__c>> getUserPreferences(
        List<List<Resource__c>> pResourceList
    ){

        Set<Id> resourceIdSet = new Set<Id>();

        for( Resource__c r_i : pResourceList[0] ){

            resourceIdSet.add( r_i.Id );
        }

        List<Resource_Preference__c> resourcePreferenceList = new List<Resource_Preference__c>([
            SELECT
                Id,
                Resource__c,
                Order__c
            FROM
                Resource_Preference__c
            WHERE
                    Resource__c IN :resourceIdSet
                AND OwnerId = :UserInfo.getUserId()
        ]);

        List<List<Resource_Preference__c>> rp = new List<List<Resource_Preference__c>>();
        rp.add( resourcePreferenceList );
        return rp;
    }
}