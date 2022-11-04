import { Octokit } from "octokit";

const octokit = new Octokit({ auth: `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` });

export const publish = async (repo, retain = 0) => {
    // touch each project
    // commit
    // push
}
