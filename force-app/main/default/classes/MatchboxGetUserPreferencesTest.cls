@IsTest
private class MatchboxGetUserPreferencesTest {
    
    /**
     * GIVEN: A collection, category, resources, user with preferences for resources
     * WHEN: Get user preferences is ran
     * THEN: Resources preferences are returned
     *
     * @return void
     */
    static testMethod void getUserPreferencesTest() {

        // Create a collection, cateogry with 2 resources
        Resource_Collection__c resourceCollection = new Resource_Collection__c(
            Name = 'Test Collection'
        );
        
        Database.insert( resourceCollection );
        
        Resource_Category__c resourceCategory = new Resource_Category__c(
            Name = 'Test Category',
            Resource_Collection__c = resourceCollection.Id,
            Diversity_Fields__c = 'City;Department;Title',
            Select_Preferred_Based_On_Diversity__c = true
        );
        
        Database.insert( resourceCategory );
        
        List<Resource__c> resourceList = new List<Resource__c>{
            new Resource__c(
                Name = 'Resource 1',
                Number_of_Slots__c = 2,
                Resource_Category__c = resourceCategory.Id
            ),
            new Resource__c(
                Name = 'Resource 2',
                Number_of_Slots__c = 2,
                Resource_Category__c = resourceCategory.Id
            )
        };
        
        Database.insert( resourceList );

        // Create a user with preferences for resources
        List<User> userList = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];

        userList.add( 
            new User(
                Alias = 'standt',
                Email='standarduser@example.com', 
                EmailEncodingKey='UTF-8',
                LastName='Testing',
                LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US',
                ProfileId = p.Id, 
                TimeZoneSidKey='America/Los_Angeles',
                UserName= (1)+'standarduser'+Math.random()+'@example.com'
            )
        );

        Database.insert( userList );

        List<Resource_Preference__c> resourcePreferenceList = new List<Resource_Preference__c>{
            new Resource_Preference__c(
                OwnerId = userList[0].Id,
                Resource__c = resourceList[0].Id,
                Order__c = 1,
                Matched__c = false
            ),
            new Resource_Preference__c(
                OwnerId = userList[0].Id,
                Resource__c = resourceList[1].Id,
                Order__c = 2,
                Matched__c = false
            )
        };

        Database.insert( resourcePreferenceList );

        List<List<Resource_Preference__c>> userResourcePreferences;

        // Get user preferences
        Test.startTest();

            System.runAs(userList[0]) {
                userResourcePreferences =  MatchboxGetUserPreferences.getUserPreferences(
                    new List<List<Resource__c>>{
                        resourceList
                    }
                );
            }
        
        Test.stopTest();

        // Assert we get the users resource preferences
        System.assertEquals(
            userResourcePreferences[0].size(),
            2
        );
    }
}
