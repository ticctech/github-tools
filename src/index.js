
import { deleteReleases } from "./releases.js";
import { readFileSync, accessSync, constants } from 'node:fs';
import { cwd } from 'node:process'

import apiSpec from './docs.swagger.json' assert { type: "json" };

const main = async () => {
    //const apiSpec = require(`${cwd()}/src/docs.swagger.json`)
    const res = Buffer.from(JSON.stringify(apiSpec)).toString('base64')

    //let apiSpec = ''
    // try {
    //     apiSpec = readFileSync(`${cwd()}/src/docs.swagger.json`, 'base64')
    // } catch (e) {}

    console.log(res)
    // await deleteReleases('report', 20);
    // createRelease('report', 'v0.5.0-beta.0');
}

main();