
import { deleteReleases } from "releases";


const main = async () => {
    await deleteReleases('report', 20);
    // createRelease('report', 'v0.5.0-beta.0');
}

main();