
import { Octokit } from "octokit";
import semver from 'semver';
// import jsonDiff from 'json-diff';

// import currProto from './curr.json' assert {type: 'json'};
// import prevProto from './prev.json' assert {type: 'json'};

const octokit = new Octokit({ auth: `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` });

const deleteReleases = async (repo) => {
    const relIter = octokit.paginate.iterator(octokit.rest.repos.listReleases, {
        owner: 'ticctech',
        repo: repo,
        per_page: 100,
    });

    // iterate through all releases
    for await (const { data: releases } of relIter) {
        for (const rel of releases) {
            octokit.rest.repos.deleteRelease({
                owner: 'ticctech',
                repo,
                release_id: rel.id,
            });

            octokit.rest.git.deleteRef({
                owner: 'ticctech',
                repo,
                ref: `tags/${rel.tag_name}`,
            });
        }
    }
}

const createRelease = async (repo, tag) => {
    octokit.rest.repos.createRelease({
        owner: 'ticctech',
        repo,
        tag_name: tag,
        // prerelease: true
    })
}

const deleteRelease = async (repo, tag) => {
    const rel = await octokit.rest.repos.getReleaseByTag({
        owner: 'ticctech',
        repo,
        tag: tag,
    });

    await octokit.rest.repos.deleteRelease({
        owner: 'ticctech',
        repo,
        release_id: rel.data.id,
    });

    octokit.rest.git.deleteRef({
        owner: 'ticctech',
        repo,
        ref: `tags/${tag}`,
    });
}

const increment = () => {
    let ver = semver.inc('v0.0.1-alpha.0', 'prerelease', 'alpha');
    ver = semver.inc(ver, 'patch');
    ver = semver.inc(ver, 'prerelease', 'alpha');
    console.log(ver);

    const latestTag = 'v0.0.1-alpha.0';
    let increment = ''

    if (semver.prerelease(latestTag)) {
        increment = 'prerelease'
    } else if (deepEqual(currProto, prevProto)) {
        increment = 'patch'
    } else {
        increment = 'minor'
    }
    console.log(semver.inc(latestTag, increment))
}

const main = async () => {
    await deleteReleases('report');
    createRelease('report', 'v0.5.0-beta.0');
}

main();