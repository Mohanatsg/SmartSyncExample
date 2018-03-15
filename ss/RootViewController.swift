/*
 Copyright (c) 2015-present, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation
import UIKit
import SalesforceSDKCore
import SalesforceSwiftSDK
import PromiseKit
import SmartStore
import SmartSync
class RootViewController : UITableViewController
{
    var dataRows = [NSDictionary]()
    var syncMgr:SFSmartSyncSyncManager!
    var store:SFSmartStore!
    
    // MARK: - View lifecycle
    override func loadView()
    {
        super.loadView()
        self.title = "Mobile SDK Sample App"
        let restApi = SFRestAPI.sharedInstance()
        restApi.Promises
            .query(soql: "SELECT Name FROM User LIMIT 10")
            .then {  request  in
                restApi.Promises.send(request: request)
            }.done { [unowned self] response in
                self.dataRows = response.asJsonDictionary()["records"] as! [NSDictionary]
                SalesforceSwiftLogger.log(type(of:self), level:.debug, message:"request:didLoadResponse: #records: \(self.dataRows.count)")
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
            }.catch { error in
                SalesforceSwiftLogger.log(type(of:self), level:.debug, message:"Error: \(error)")
        }
        
        let CONTACTS_SOUP = "Contact"
        var contactIds:[String] = []
        syncMgr = SFSmartSyncSyncManager.sharedInstance(SFUserAccountManager.sharedInstance().currentUser!)
        
        
        
        // Store Creation .....
        
        func storeCreation() {
            
            store = SFSmartStore.sharedStore(withName: "DefaultSFDB", user: SFUserAccountManager.sharedInstance().currentUser!) as! SFSmartStore
            
            //  store =  SFSmartStore.sharedStore(withName: "DefaultSFDB") as! SFSmartStore
            let storePath =  store.storePath
            
            print("DataBase Path is  \(storePath)")
            let isSoupExist = store.soupExists(CONTACTS_SOUP)
            
            if isSoupExist{
                
                print("Soup is present")
            }
            else{
                print("need to create soup")
            }
            
        }
        
        
        // Soup Creation
        
        
        func createAndRegisterContactSoup(){
            
            
            let ID = "Id"
            let DESCRIPTION = "Description"
            let FIRST_NAME = "FirstName"
            let LAST_NAME = "LastName"
            let TITLE = "Title"
            let MOBILE_PHONE = "MobilePhone"
            let EMAIL = "Email"
            let HOME_PHONE = "HomePhone"
            
            
            let indexSpecs:[AnyObject]! = [
                SFSoupIndex(path: ID, indexType: kSoupIndexTypeString, columnName: nil)!,
                SFSoupIndex(path:FIRST_NAME, indexType:kSoupIndexTypeString, columnName:nil)!,
                SFSoupIndex(path:LAST_NAME, indexType:kSoupIndexTypeString, columnName:nil)!,
                SFSoupIndex(path:TITLE, indexType:kSoupIndexTypeString, columnName:nil)!,
                SFSoupIndex(path:MOBILE_PHONE, indexType:kSoupIndexTypeString, columnName:nil)!,
                SFSoupIndex(path:HOME_PHONE, indexType:kSoupIndexTypeString, columnName:nil)!,
                SFSoupIndex(path:EMAIL, indexType:kSoupIndexTypeString, columnName:nil)!,
                SFSoupIndex(path:DESCRIPTION, indexType:kSoupIndexTypeFullText, columnName:nil)!,
                SFSoupIndex(path:kSyncTargetLocal, indexType:kSoupIndexTypeString, columnName:nil)!,
                //SFSoupIndex(path:kSyncTargetSyncId, indexType:kSoupIndexTypeInteger, columnName:nil)!
            ]
            
            do {
                
                try store.registerSoup(CONTACTS_SOUP, withIndexSpecs: indexSpecs, error: ())
                print("Registered Soup names... \(store.allSoupNames()) ")
            } catch {
                print("Can not Registered the Soup")
            }
            
            
            let  exists = store.soupExists(CONTACTS_SOUP)
            
            if exists {
                print("contact soup is created")
            }
            else{
                
                print("Contact soup creation failed")
                
            }
            
            
        }
        // calling sync down .....
        
        func createSyncDownTargetForDefaultSFDB(contactIds: [String]) -> SFSoqlSyncDownTarget {
            let ID = "Id"
            let DESCRIPTION = "Description"
            let FIRST_NAME = "FirstName"
            let LAST_NAME = "LastName"
            let TITLE = "Title"
            let MOBILE_PHONE = "MobilePhone"
            let EMAIL = "Email"
            let HOME_PHONE = "HomePhone"
            var contactFieldList = [ID,FIRST_NAME,LAST_NAME,DESCRIPTION,TITLE,MOBILE_PHONE,EMAIL,HOME_PHONE]
            
            let inString = contactIds.joined(separator: "','")
            //let soqlQuery = "Select \(contactFieldList.joined(separator: ",")) from Contact )"
            let soqlQuery = "Select \(contactFieldList.joined(separator: ",")) from Contact limit 20"
            let syncTarget = SFSoqlSyncDownTarget.newSyncTarget(soqlQuery)
            return syncTarget
        }
        
        func tryingSyncDown(){
            
            let SFsyncDownTarget = createSyncDownTargetForDefaultSFDB(contactIds: contactIds)
            
            //            syncMgr.reSync(byName: "syncDownContacts", update: { sync in
            //                if(sync.isDone()){
            //
            //                    print("Success")
            //
            //                }
            //
            //
            //
            //            })
            
            syncMgr.syncDown(with: SFsyncDownTarget, soupName: CONTACTS_SOUP) { (sync: SFSyncState?) in
                if (sync?.isDone())!{
                    
                    print("Sync Completed Successfully")
                    print("Sync down has been completed")
                    
                    
                    self.readContactDataFromStore()
                    
                }else
                    if sync!.hasFailed(){
                        print("Sync Failed ")
                        
                }
            }
            
            
            
        }
        
        
        
        
        // calling store creation
        
        storeCreation()
        createAndRegisterContactSoup()
        tryingSyncDown()
        
        
        
        
        
        //Global Constants
        
        let TYPE = "type"
        let ATTRIBUTES = "attributes"
        let RECORDS = "records"
        let LOCAL_ID_PREFIX = "local_"
        let REMOTELY_UPDATED = "_r_upd"
        let LOCALLY_UPDATED = "_l_upd"
        let CONTACT_TYPE = "Contact"
        
        let ID = "Id"
        let DESCRIPTION = "Description"
        let FIRST_NAME = "FirstName"
        let LAST_NAME = "LastName"
        let TITLE = "Title"
        let MOBILE_PHONE = "MobilePhone"
        let EMAIL = "Email"
        let HOME_PHONE = "HomePhone"
        var contactFieldList = [ID,FIRST_NAME,LAST_NAME,DESCRIPTION,TITLE,MOBILE_PHONE,EMAIL,HOME_PHONE]
        var contactSyncFieldList = [FIRST_NAME,LAST_NAME,DESCRIPTION,TITLE,MOBILE_PHONE,EMAIL,HOME_PHONE]
        
        func createContactsSoup(){
            do{
                let indexSpecs:[AnyObject]! = [
                    SFSoupIndex(path: ID, indexType: kSoupIndexTypeString, columnName: nil)!,
                    SFSoupIndex(path:FIRST_NAME, indexType:kSoupIndexTypeString, columnName:nil)!,
                    SFSoupIndex(path:LAST_NAME, indexType:kSoupIndexTypeString, columnName:nil)!,
                    SFSoupIndex(path:TITLE, indexType:kSoupIndexTypeString, columnName:nil)!,
                    SFSoupIndex(path:MOBILE_PHONE, indexType:kSoupIndexTypeString, columnName:nil)!,
                    SFSoupIndex(path:HOME_PHONE, indexType:kSoupIndexTypeString, columnName:nil)!,
                    SFSoupIndex(path:EMAIL, indexType:kSoupIndexTypeString, columnName:nil)!,
                    SFSoupIndex(path:DESCRIPTION, indexType:kSoupIndexTypeFullText, columnName:nil)!,
                    SFSoupIndex(path:kSyncTargetLocal, indexType:kSoupIndexTypeString, columnName:nil)!,
                    //SFSoupIndex(path:kSyncTargetSyncId, indexType:kSoupIndexTypeInteger, columnName:nil)!
                ]
                let kSSExternalStorage_TestSoupName = ["SSExternalStorage_TestSoupName"];
                let ssSoupSpec  = SFSoupSpec.newSoupSpec(CONTACTS_SOUP,withFeatures: kSSExternalStorage_TestSoupName)
                
                try syncMgr.store.registerSoup(with: ssSoupSpec, withIndexSpecs: indexSpecs)
                
            }catch {
                SalesforceSwiftLogger.log(type(of:self), level:.debug, message:"Error: \(error)")
            }
            
            // syncMgr.store.registerSoup(soupName: CONTACTS_SOUP, withIndexSpecs: indexSpecs)
        }
        
        //   createContactsSoup()
        
        //        func createSyncDownTargetFor(contactIds: [String]) -> SFSoqlSyncDownTarget {
        //            let inString = contactIds.joined(separator: "','")
        //            //let soqlQuery = "Select \(contactFieldList.joined(separator: ",")) from Contact )"
        //            let soqlQuery = "Select \(contactFieldList.joined(separator: ",")) from Contact limit 20"
        //            let syncTarget = SFSoqlSyncDownTarget.newSyncTarget(soqlQuery)
        //            return syncTarget
        //        }
        //
        
        //        let syncDownTarget = createSyncDownTargetFor(contactIds: contactIds)
        //
        //        syncMgr.syncDown(with: syncDownTarget, soupName: CONTACTS_SOUP) { (sync: SFSyncState?) in
        //            if sync!.isDone() {
        //                print("Sync Completed Successfully")
        //
        //                var querySpec = SFQuerySpec.newSmartQuerySpec("select count(*) from {contact_soup}", withPageSize: 2);
        //
        //                print("####################")
        //
        //
        //
        //              try syncMgr.store.registerSoup(with: ssSoupSpec, withIndexSpecs: indexSpecs)
        //
        //                print(self.syncMgr.store.allSoupNames())
        //                print(self.syncMgr.store.getDatabaseSize())
        //                print(self.syncMgr.store.storeName)
        //                var error : NSError?
        //                var result = self.syncMgr.store.query(with: querySpec!, pageIndex: 0, error: &error)
        //
        //                print(result)
        //
        //                var querySpec = SFQuerySpec.newSmartQuerySpec("select count(*) from {employees}", withPageSize: 1)
        //                var result = store.query(with: querySpec, pageIndex: 0, error: nil)
        //
        //
        //                print(querySpecc)
        //
        //
        //
        //
        //            }else
        //                if sync!.hasFailed(){
        //                    print("Sync Failed ")
        //
        //            }
        //        }
        //
        
        
        
    }
    
    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView?, numberOfRowsInSection section: Int) -> Int
    {
        return self.dataRows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cellIdentifier = "CellIdentifier"
        
        // Dequeue or create a cell of the appropriate type.
        var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier:cellIdentifier)
        if (cell == nil)
        {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
        
        // If you want to add an image to your cell, here's how.
        let image = UIImage(named: "icon.png")
        cell!.imageView!.image = image
        
        // Configure the cell to show the data.
        let obj = dataRows[indexPath.row]
        cell!.textLabel!.text = obj["Name"] as? String
        
        // This adds the arrow to the right hand side.
        cell?.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        
        return cell!
    }
    
    func readContactDataFromStore(){
        
        // NSString* const kContactsQuery = @"SELECT {Contacts:uid},{Contacts:firstName}, {Contacts:lastName}, {Contacts:phonenumber} FROM {Contacts}";
        
        var querySpec = SFQuerySpec.newSmartQuerySpec("SELECT {Contact:Id} FROM {Contact}", withPageSize: 20)
        
        
        //let query2 = SFQuerySpec.newAllQuerySpec("contact_soup", withOrderPath: "LastName", with: SFSoupQuerySortOrder.ascending, withPageSize: 1000)
        
        var error : NSError?
        
        let result = store.query(with: querySpec!, pageIndex: 0, error: &error)
        
        print("The result is \(result)")
        
        // result should be [[ n ]] if there are n employees
        
        //  let query = "select * from {contact_soup}"
        
        //  SFQuerySpec *sobjectsQuerySpec = [SFQuerySpec newAllQuerySpec (worry) elf.dataSpec.soupName withOrderPath (worry) elf.dataSpec.orderByFieldName withOrder:kSFSoupQuerySortOrderAscending withPageSize:kMaxQueryPageSize];
        
        //   let query2 = SFQuerySpec.newAllQuerySpec("contact_soup", withOrderPath: "LastName", with: SFSoupQuerySortOrder.ascending, withPageSize: 1000)
        
        //if let querySpec = SFQuerySpec.newSmartQuerySpec(query, withPageSize: 1000){
        
        //     print("stores are \(store.allSoupNames())")
        
        //    var error : NSError?
        
        //    let contactArray =  store.query(with: query2, pageIndex: 0, error: &error)
        //
        //   print("Contact Array is \(contactArray)")
        //        }
        //        else {
        //
        //            print("in error")
        //        }
        
        
    }
}

