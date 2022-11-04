import { Octokit } from "octokit";

const octokit = new Octokit({ auth: `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` });

export const deleteReleases = async (repo, retain = 0) => {
    // get matching releases
    const relIter = octokit.paginate.iterator(octokit.rest.repos.listReleases, {
        owner: 'ticctech',
        repo: repo,
        page: retain ? 1 : 0,
        per_page: retain ? retain : 100,
    });

    // iterate through releases
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

export const createRelease = async (repo, tag) => {
    octokit.rest.repos.createRelease({
        owner: 'ticctech',
        repo,
        tag_name: tag,
        // prerelease: true
    })
}