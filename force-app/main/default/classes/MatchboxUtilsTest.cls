@isTest 
private class MatchboxUtilsTest {

    /**
     * GIVEN: A collection, category, resources, and 14 users with specific preferences
     * WHEN: Matching mechanism is ran
     * THEN: 12 users will have been assigned matches
     *
     * @return void
     */
    static testMethod void assignMatchesForResourceCategoryTest() {
        
        List<User> userList = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        
        // Create 14 Users
        for( Integer i=0; i<14; i++ ){
            
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
                    UserName= (i+1)+'standarduser'+Math.random()+'@example.com'
                )
            );
        }
        
        Database.insert( userList );
        
        System.debug( userList );
        
        Resource_Collection__c resourceCollection = new Resource_Collection__c(
            Name = 'Test Collection',
            Matching_Status__c = 'Not Started'
        );
        
        // Create 5 resources
        Database.insert( resourceCollection );
        
        Resource_Category__c resourceCategory = new Resource_Category__c(
            Name = 'Test Category',
            Resource_Collection__c = resourceCollection.Id
        );
        
        Database.insert( resourceCategory );
        
        List<Resource__c> resourceList = new List<Resource__c>{
            new Resource__c(
                Name = 'Resource 1',
                Number_of_Slots__c = 3,
                Resource_Category__c = resourceCategory.Id
            ),
            new Resource__c(
                Name = 'Resource 2',
                Number_of_Slots__c = 3,
                Resource_Category__c = resourceCategory.Id
            ),
            new Resource__c(
                Name = 'Resource 3',
                Number_of_Slots__c = 2,
                Resource_Category__c = resourceCategory.Id
            ),
            new Resource__c(
                Name = 'Resource 4',
                Number_of_Slots__c = 2,
                Resource_Category__c = resourceCategory.Id
            ),
            new Resource__c(
                Name = 'Resource 5',
                Number_of_Slots__c = 3,
                Resource_Category__c = resourceCategory.Id
            )
        };
        
        Database.insert( resourceList );
        
        // Create a pre-determined list of resource preferences
        Map<Integer, Map<Integer,Integer>> prefMap = new Map<Integer, Map<Integer,Integer>>{
            1 => new Map<Integer, Integer>{
                1 => 3,
                2 => 1,
                3 => 5,
                4 => 4
            },
            2 => new Map<Integer, Integer>{
                1 => 1,
                2 => 2,
                3 => 3
            },
            3 => new Map<Integer, Integer>{
                1 => 3,
                2 => 5,
                3 => 2
            },
            4 => new Map<Integer, Integer>{
                1 => 3,
                2 => 4,
                3 => 1
            },
            5 => new Map<Integer, Integer>{
                1 => 1,
                2 => 5,
                3 => 2,
                4 => 3
            },
            6 => new Map<Integer, Integer>{
                1 => 1,
                2 => 5,
                3 => 4
            },
            7 => new Map<Integer, Integer>{
                1 => 1,
                2 => 2,
                3 => 5,
                4 => 4
            },
            8 => new Map<Integer, Integer>{
                1 => 3,
                2 => 2,
                3 => 1
            },
            9 => new Map<Integer, Integer>{
                1 => 2,
                2 => 5,
                3 => 4,
                4 => 3
            },
            10 => new Map<Integer, Integer>{
                1 => 3,
                2 => 5,
                3 => 1,
                4 => 2
            },
            11 => new Map<Integer, Integer>{
                1 => 4,
                2 => 3,
                3 => 2
            },
            12 => new Map<Integer, Integer>{
                1 => 4,
                2 => 5
            },
            13 => new Map<Integer, Integer>{
                1 => 3,
                2 => 1,
                3 => 4
            },
            14 => new Map<Integer, Integer>{
                1 => 4,
                2 => 3,
                3 => 2,
                4 => 1
            }
        };
        
        
        List<Resource_Preference__c> resourcePreferenceList = new List<Resource_Preference__c>();
        
        for( Integer i : prefMap.keySet() ){
        
            for( Integer i2 : prefMap.get( i ).keySet() ){
        
                resourcePreferenceList.add(
                    new Resource_Preference__c(
                        OwnerId      = userList[i-1].Id,
                        Resource__c  = resourceList[ prefMap.get( i ).get( i2 ) - 1 ].Id,
                        Order__c     = i2
                    )
                );
            }
        }
        
        Database.insert( resourcePreferenceList );
        
        Map<Id,Resource_Preference__c> resourcePreferenceMap;
        
        // Run matching mechanism
        Test.startTest();
        
            resourcePreferenceMap =  MatchboxUtils.assignMatchesForResourceCategory(
                resourceCategory,
                userList
            );
            
        Test.stopTest();
        
        // Assert that 12 users were assigned matches
        System.assertEquals(
            resourcePreferenceMap.values().size(),
            12
        
        );
    }
}
