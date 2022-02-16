/**
 *
 * Sync to analysis.clue.io and then link roles in clue
 *
 */
class Analysis2clue {
    /**
     *
     * @param apiKey - The API Key
     * @param apiURL - The API URL
     * @param buildID - The ID of teh CLUE build
     * @param projectName - the name of the project to be used as folder name on analysis.clue.io
     * @param indexFile - full path to the index.html file
     */
    constructor(apiKey, apiURL, buildID, projectName, indexFile) {
        this.apiKey = apiKey;
        this.apiURL = apiURL;
        this.indexFile = indexFile;
        this.projectName = projectName.replace(/_/g, " ");
        const whereClause = {"name": this.projectName};
        this.resourceExistsURL = this.apiURL + "/api/preliminary-analysis/count?where=" + JSON.stringify(whereClause);
        this.postURL = this.apiURL + "/api/data/" + buildID + "/external_analysis";
    }

    /**
     *
     * Check if the resource already exists in clue
     *
     * @returns {Promise<any>}
     */
    async resourceExists() {
        const fetch = require("node-fetch");
        const self = this;
        const options = {
            method: 'GET',
            headers: {
                'user_key': self.apiKey
            }
        };
        console.log("self.resourceExistsURL", self.resourceExistsURL)
        const response = await fetch(self.resourceExistsURL, options);
        if (response.status === 404) {
            return {count: 0}
        }
        //check  if it exist before you do anything
        const respJSON = await response.json();
        return respJSON;
    }

    /**
     *
     * @param message
     * @param url
     * @param method
     * @returns {Promise<Response>}
     *
     */
    async postMethodAPI(message, url, method) {
        const fetch = require("node-fetch");
        const self = this;
        const payload = JSON.stringify(message);
        const options = {
            method: method,
            body: payload,
            headers: {
                "Content-Type": "application/json",
                'Content-Length': Buffer.byteLength(payload),
                "user_key": self.apiKey
            }
        };
        return await fetch(url, options);
    }

    /**
     *
     * Register resource in CLUE
     *
     * @returns {Promise<{id: *}>}
     *
     */
    async registerInCLUE() {
        const self = this;
        //check if resource exists in API before you post
        const counter = await self.resourceExists();
        if (counter && counter.count && counter.count > 0) {
            console.log(self.projectName + " already exists");
            return {ignore: true};
        }
        const postData = {
            "name": self.projectName,
            "description": self.projectName,
            "url": self.indexFile,
            "created_by": "MTS"
        };
        const resp = await self.postMethodAPI(postData, self.postURL, "POST");
        const data = await resp.json();
        if (resp.ok && resp.status < 300) {
            return {ignore: false, id: data.id};
        }
        return {ignore: true};
    }

    /**
     *
     * @param prelim_analysisID - The ID to associate the preliminary analysis to cmap_core
     */
    async associateAnalysis2Role(prelim_analysisID) {
        const self = this;
        const url = self.apiURL + "/api/preliminary-analysis/" + prelim_analysisID + "/role/rel/cmap_core";
        const resp = await self.postMethodAPI({}, url, "PUT");

        if (resp.ok && resp.status < 300) {
            return {success: "success"};
        }
        return {failure: "failure"};
    }

    /**
     *
     * Start the processing
     * @returns {Promise<string>}
     *
     */
    async start() {
        const self = this;
        const resp = await self.registerInCLUE();
        if (!resp.ignore && resp.id) {
            await self.associateAnalysis2Role(resp.id);
        }
        return "done";
    }
}

module.exports = Analysis2clue;