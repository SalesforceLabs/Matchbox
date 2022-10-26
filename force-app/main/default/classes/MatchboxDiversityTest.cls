@isTest 
private class MatchboxDiversityTest {

    /**
     * GIVEN: A list of 10 diverse users
     * WHEN: A get diverse group of 5 based on city, department, title is ran
     * THEN: We will get back a list of 5 users
     *
     * @return void
     */
    static testMethod void getDiverseGroupTest() {

        // Create list of 10 diverse users
        List<User> userList = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];

        Integer cityListIndex = 0;
        Integer departmentListIndex = 0;
        Integer titleListIndex = 0;

        List<String> cityList = new List<String>{
            'Detroit',
            'Chicago',
            'New York'
        };

        List<String> departmentList = new List<String>{
            'Marketing',
            'Finance',
            'Legal',
            'IT',
            'Sales'
        };
        List<String> titleList = new List<String>{
            'Developer',
            'Manager',
            'Director',
            'VP'
        };
        
        // Create 10 Users
        for( Integer i=0; i<10; i++ ){
            
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
                    UserName= (i+1)+'standarduser'+Math.random()+'@example.com',
                    City = cityList[cityListIndex],
                    Department = departmentList[departmentListIndex],
                    Title = titleList[titleListIndex]
                )
            );

            cityListIndex++;
            departmentListIndex++;
            titleListIndex++;

            if( cityListIndex == cityList.size() ){
                cityListIndex = 0;
            }
            if( departmentListIndex == departmentList.size() ){
                departmentListIndex = 0;
            }
            if( titleListIndex == titleList.size() ){
                titleListIndex = 0;
            }
        }
        
        Database.insert( userList );

        Map<Id,User> userMap = new Map<Id,User>();

        for( User u_i : userList ){

            userMap.put(
                u_i.Id,
                u_i
            );
        }

        Map<Id,SObject> SObjectMap;

        // Get Diverse Group
        Test.startTest();

            SObjectMap = MatchboxDiversity.getDiverseGroup(
                userMap,
                new List<String> {'City','Department','Title'},
                5
            );
        
        Test.stopTest();

        // Assert we get 5 users back
        System.assertEquals(
            SObjectMap.values().size(),
            5
        );
    }



    /**
     * GIVEN: A list of 4 diverse users with resource preferences
     * WHEN: assignDiverseResourcePreferences is ran for category
     * THEN: The resources preferences returned will be marked as preferred by resource owner
     *
     * @return void
     */
    static testMethod void assignDiverseResourcePreferencesTest() {

        // Create a collection with 2 resources
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

        // Create list of 4 diverse users
        List<User> userList = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];

        Integer cityListIndex = 0;
        Integer departmentListIndex = 0;
        Integer titleListIndex = 0;

        List<String> cityList = new List<String>{
            'Detroit',
            'Chicago',
            'New York'
        };

        List<String> departmentList = new List<String>{
            'Marketing',
            'Finance',
            'Legal',
            'IT',
            'Sales'
        };
        List<String> titleList = new List<String>{
            'Developer',
            'Manager',
            'Director',
            'VP'
        };
        
        for( Integer i=0; i<4; i++ ){
            
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
                    UserName= (i+1)+'standarduser'+Math.random()+'@example.com',
                    City = cityList[cityListIndex],
                    Department = departmentList[departmentListIndex],
                    Title = titleList[titleListIndex]
                )
            );

            cityListIndex++;
            departmentListIndex++;
            titleListIndex++;

            if( cityListIndex == cityList.size() ){
                cityListIndex = 0;
            }
            if( departmentListIndex == departmentList.size() ){
                departmentListIndex = 0;
            }
            if( titleListIndex == titleList.size() ){
                titleListIndex = 0;
            }
        }
        
        Database.insert( userList );

        Map<Id,User> userMap = new Map<Id,User>();

        for( User u_i : userList ){

            userMap.put(
                u_i.Id,
                u_i
            );
        }

        // Create resource preferences for each users
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
            ),
            new Resource_Preference__c(
                OwnerId = userList[1].Id,
                Resource__c = resourceList[0].Id,
                Order__c = 1,
                Matched__c = false
            ),
            new Resource_Preference__c(
                OwnerId = userList[2].Id,
                Resource__c = resourceList[0].Id,
                Order__c = 1,
                Matched__c = false
            ),
            new Resource_Preference__c(
                OwnerId = userList[2].Id,
                Resource__c = resourceList[1].Id,
                Order__c = 2,
                Matched__c = false
            ),
            new Resource_Preference__c(
                OwnerId = userList[3].Id,
                Resource__c = resourceList[1].Id,
                Order__c = 1,
                Matched__c = false
            )
        };

        Database.insert( resourcePreferenceList );

        // Assign diversity preferences
        Test.startTest();

            Map<Id,Resource_Preference__c> selectedResourcePreferenceMap = MatchboxDiversity.assignDiverseResourcePreferences(
                resourceCategory
            );
        
        Test.stopTest();

        // Assert that there are returned resource preferences and all marked as preferred
        System.assertEquals(
            selectedResourcePreferenceMap.values().size() > 0,
            true
        );

        Boolean allMarkedPreferred = true;

        for( Resource_Preference__c rp_i : selectedResourcePreferenceMap.values() ){
            
            if( rp_i.Preferred_By_Resource_Owner__c == false ){
                allMarkedPreferred = false;
            }
        }
        
        System.assertEquals(
            allMarkedPreferred,
            true
        );
    }
}
