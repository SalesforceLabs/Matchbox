import { LightningElement, api, wire, track } from 'lwc';
import Id from '@salesforce/user/Id';

export default class ResourcePreferences extends LightningElement {

    userId = Id;

    /**
     * Track current preferences when initialized and as user interacts prefers and unprefers resources
     */
    @track currentPreferences;

    /**
     * Lists of resources preferences to pass back to Flow that executes DML statements for
     */
    @api resourcePreferenceInsertCollection;
    @api resourcePreferenceUpdateCollection;
    @api resourcePreferenceDeleteCollection;

    /**
     * Current resources passed into component
     *
     * @param  value    A list of resources   
     * @return _resourceList
     */
    @api
    get resourceList() {
        return this._resourceList;
    }
    set resourceList(value) {
        this.setAttribute('resourceList', value);
        this._resourceList = value;
        this.setup();
    }

    /**
     * Current resource preferences passed into component
     *
     * @param  value    A list of resource preferences   
     * @return _resourcePreferenceList
     */
    @api
    get resourcePreferenceList() {
        return this._resourcePreferenceList;
    }
    set resourcePreferenceList(value) {
        this.setAttribute('resourcePreferenceList', value);
        this._resourcePreferenceList = value;
        this.setup();
    }

    /**
     * When component is initialized, current preferences array is set and DML array are synced
     *
     * @return null
     */
    setup(){
        this.currentPreferences = [];

        for( var i=0; i<this._resourceList.length; i++ ){

            let preference = null;

            if( this._resourcePreferenceList ){
                
                preference = this._resourcePreferenceList.find( (item) => item.matchbox__Resource__c ===  this._resourceList[i].Id );
            }
            
            this.currentPreferences.push(
                {
                    "Name": this._resourceList[i].Name,
                    "Id": this._resourceList[i].Id,
                    "ResourcePreferenceId": preference ? preference.Id : null,
                    "IsPreferred": preference ? true : false,
                    "Order": preference ? preference.matchbox__Order__c : 999
                }
            );
        }

        this.currentPreferences.sort( function(a, b) {
            return a.Order - b.Order;
        } );

        this.syncResourcePreferenceRecords();

    }

    /**
     * Inspect current preferences for which records to insert, update, or delete
     *
     * @return null
     */
    syncResourcePreferenceRecords(){

        let order = 1;
        for( var i=0; i<this.currentPreferences.length; i++){
            if( this.currentPreferences[i].IsPreferred ){
                this.currentPreferences[i].Order = order;
                order++;
            }
        }
        this.currentPreferences.sort( function(a, b) {
            return a.Order - b.Order;
        } );

        this.resourcePreferenceInsertCollection = [];
        this.resourcePreferenceUpdateCollection = [];
        this.resourcePreferenceDeleteCollection = [];
        for( var i=0; i<this.currentPreferences.length; i++){
            if( this.currentPreferences[i].IsPreferred && this.currentPreferences[i].ResourcePreferenceId ){
                        
                // is update
                this.resourcePreferenceUpdateCollection.push(
                    {
                        "Id": this.currentPreferences[i].ResourcePreferenceId,
                        "matchbox__Resource__c": this.currentPreferences[i].Id,
                        "matchbox__Order__c": this.currentPreferences[i].Order,
                        "OwnerId": this.userId    
                    }
                );
            }else if( this.currentPreferences[i].IsPreferred && !this.currentPreferences[i].ResourcePreferenceId ){
                
                // is insert
                // add to update list
                this.resourcePreferenceInsertCollection.push(
                    {
                        "matchbox__Resource__c": this.currentPreferences[i].Id,
                        "matchbox__Order__c": this.currentPreferences[i].Order,
                        "OwnerId": this.userId    
                    }
                );
            }else if( !this.currentPreferences[i].IsPreferred && this.currentPreferences[i].ResourcePreferenceId ){
                
                // user says it's unpreferred but has a resource preference attached to it
                // add to delete list
                this.resourcePreferenceDeleteCollection.push(
                    {
                        "Id": this.currentPreferences[i].ResourcePreferenceId,
                        "matchbox__Resource__c": this.currentPreferences[i].Id,
                        "matchbox__Order__c": this.currentPreferences[i].Order,
                        "OwnerId": this.userId    
                    }
                );
            }
        }
    }

    /**
     * Sets a resource as preferred
     *
     * @param  event    click event that called function
     * @return null
     */
    preferResource( event ) {

        let clickedId = event.currentTarget.dataset.name;
        let item = this.currentPreferences.find( (item) => item.Id ===  clickedId);
        item.IsPreferred = true;

        this.syncResourcePreferenceRecords();
    }

    /**
     * Sets a resource as unpreferred
     *
     * @param  event    click event that called function
     * @return null
     */
    unpreferResource( event ) {

        let clickedId = event.currentTarget.dataset.name;
        let item = this.currentPreferences.find( (item) => item.Id ===  clickedId);
        item.IsPreferred = false;

        this.syncResourcePreferenceRecords();
    }

    /**
     * Set a preferred resource preference order higher in the list
     *
     * @param  event    click event that called function
     * @return null
     */
    moveResourceUp( event ){
        let clickedId = event.currentTarget.dataset.name;
        let itemIndex = this.currentPreferences.findIndex( (item) => item.Id ===  clickedId);
        
        [this.currentPreferences[itemIndex-1], this.currentPreferences[itemIndex]] = [this.currentPreferences[itemIndex], this.currentPreferences[itemIndex-1]];

        this.syncResourcePreferenceRecords();
    }

    /**
     * Set a preferred resource preference order lower in the list
     *
     * @param  event    click event that called function
     * @return null
     */
    moveResourceDown( event ){
        let clickedId = event.currentTarget.dataset.name;
        let itemIndex = this.currentPreferences.findIndex( (item) => item.Id ===  clickedId);
        
        [this.currentPreferences[itemIndex], this.currentPreferences[itemIndex+1]] = [this.currentPreferences[itemIndex+1], this.currentPreferences[itemIndex]];

        this.syncResourcePreferenceRecords();
    }
}