package org.mydotey.tool.elasticsearch.ops;

import java.util.HashMap;
import org.elasticsearch.cluster.metadata.Manifest;
import org.elasticsearch.index.Index;
import org.mydotey.tool.elasticsearch.ops.state.StateMetaData;

import net.sourceforge.argparse4j.ArgumentParsers;
import net.sourceforge.argparse4j.helper.HelpScreenException;
import net.sourceforge.argparse4j.inf.ArgumentParser;
import net.sourceforge.argparse4j.inf.Namespace;

/**
 * @author koqizhao
 *
 * Dec 10, 2018
 */
public class ManifestStateFileEditor {

    private static final String KEY_SOURCE_FILE = "source-file";
    private static final String KEY_TARGET_FILE = "target-file";
    private static final String KEY_INDEX_NAME = "index-name";
    private static final String KEY_INDEX_UUID = "index-uuid";
    private static final String KEY_GENERATION = "generation";

    private static final String KEY_ACTION = "action";
    private static final String ACTION_ADD_INDEX = "add-index";

    private static ArgumentParser _argumentParser = ArgumentParsers.newFor(ManifestStateFileEditor.class.getSimpleName())
            .build();

    static {
        _argumentParser.addArgument("-s", "--" + KEY_SOURCE_FILE).dest(KEY_SOURCE_FILE).required(true);
        _argumentParser.addArgument("-t", "--" + KEY_TARGET_FILE).dest(KEY_TARGET_FILE).required(true);
        _argumentParser.addArgument("-n", "--" + KEY_INDEX_NAME).dest(KEY_INDEX_NAME).required(true);
        _argumentParser.addArgument("-u", "--" + KEY_INDEX_UUID).dest(KEY_INDEX_UUID).required(true);
        _argumentParser.addArgument("-g", "--" + KEY_GENERATION).type(Long.class).required(true);
        _argumentParser.addArgument("-a", "--" + KEY_ACTION).choices(ACTION_ADD_INDEX).setDefault(ACTION_ADD_INDEX);
    }

    public static void main(String[] args) throws Exception {
        Namespace ns;
        try {
            ns = _argumentParser.parseArgs(args);
        } catch (HelpScreenException e) {
            return;
        }

        String action = ns.getString(KEY_ACTION);
        String sourceFile = ns.get(KEY_SOURCE_FILE);
        String targetFile = ns.get(KEY_TARGET_FILE);
        String indexName = ns.get(KEY_INDEX_NAME);
        String indexUUID = ns.get(KEY_INDEX_UUID);
        long generation = ns.getLong(KEY_GENERATION);

        System.out.printf("\naction: %s\nsource file: %s\ntarget file: %s\n"
            + "index name: %s\nindex uuid: %s\ngeneration: %s\n\n",
            action, sourceFile, targetFile, indexName, indexUUID, generation);

        StateMetaData<Manifest> manifestMetaData = StateMetaData.newManifestMetaData(sourceFile);
        System.out.printf("\nOld State:\n%s\n\n", manifestMetaData.toJson());
        Manifest manifest = manifestMetaData.getMetaData();
        manifest = new Manifest(manifest.getCurrentTerm(), manifest.getClusterStateVersion(), manifest.getGlobalGeneration(), 
            new HashMap<Index, Long>(manifest.getIndexGenerations()));
        manifest.getIndexGenerations().put(new Index(indexName, indexUUID), generation);
        manifestMetaData = StateMetaData.newManifestMetaData(manifest);
        manifestMetaData.saveTo(targetFile);
        manifestMetaData = StateMetaData.newManifestMetaData(targetFile);
        System.out.printf("\nNew State:\n%s\n\n", manifestMetaData.toJson());
    }

}
