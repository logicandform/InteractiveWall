//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import PromiseKit


final class DataManager {

    static let instance = DataManager()

    private var places = Set<Place>()
    private var organizations = Set<Organization>()
    private var events = Set<Event>()
    private var artifacts = Set<Artifact>()
    private var schools = Set<School>()
    private var themes = Set<Theme>()


    // Use singleton instance
    private init() { }


    // MARK: API

    /// Gets all records from database and saves them locally
    func getAllRecords() {
        getAllOrganizations()
        getAllEvents()
        getAllArtifacts()
        getAllSchools()
        getAllThemes()
    }

    // api to query and fetch from the different Sets (i.e. places, schools, etc)
    




    // MARK: Helpers

    private func getAllOrganizations() {
        firstly {
            try CachingNetwork.getOrganizations()
        }.then { [weak self] organizations in
            self?.organizations = Set(organizations)
        }.catch { error in
            print(error.localizedDescription)
        }
    }

    private func getAllEvents() {
        firstly {
            try CachingNetwork.getEvents()
        }.then { [weak self] events in
            self?.events = Set(events)
        }.catch { error in
            print(error.localizedDescription)
        }
    }

    private func getAllArtifacts() {
        firstly {
            try CachingNetwork.getArtifacts()
        }.then { [weak self] artifacts in
            self?.artifacts = Set(artifacts)
        }.catch { error in
            print(error.localizedDescription)
        }
    }

    private func getAllSchools() {
        firstly {
            try CachingNetwork.getSchools()
        }.then { [weak self] schools in
            self?.schools = Set(schools)
        }.catch { error in
            print(error.localizedDescription)
        }
    }

    private func getAllThemes() {
        firstly {
            try CachingNetwork.getThemes()
        }.then { [weak self] themes in
            self?.themes = Set(themes)
        }.catch { error in
            print(error.localizedDescription)
        }
    }



}
