package org.mydotey.tool.elasticsearch.ops;

import java.util.List;
import java.lang.reflect.Method;
import java.util.ArrayList;
import org.elasticsearch.cluster.metadata.IndexGraveyard;
import org.elasticsearch.cluster.metadata.IndexGraveyard.Tombstone;
import org.elasticsearch.cluster.metadata.MetaData;
import org.elasticsearch.index.Index;
import org.mydotey.java.StringExtension;
import org.mydotey.java.collection.CollectionExtension;
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
public class ClusterStateFileEditor {

    private static final String KEY_SOURCE_FILE = "source-file";
    private static final String KEY_TARGET_FILE = "target-file";
    private static final String KEY_INDEX_NAME = "index-name";
    private static final String KEY_INDEX_UUID = "index-uuid";

    private static final String KEY_ACTION = "action";
    private static final String CLEAR_INDEX_DELETION = "clear-index-deletion";

    private static ArgumentParser _argumentParser = ArgumentParsers.newFor(ClusterStateFileEditor.class.getSimpleName())
            .build();

    static {
        _argumentParser.addArgument("-s", "--" + KEY_SOURCE_FILE).dest(KEY_SOURCE_FILE).required(true);
        _argumentParser.addArgument("-t", "--" + KEY_TARGET_FILE).dest(KEY_TARGET_FILE).required(false);
        _argumentParser.addArgument("-n", "--" + KEY_INDEX_NAME).dest(KEY_INDEX_NAME).required(false);
        _argumentParser.addArgument("-u", "--" + KEY_INDEX_UUID).dest(KEY_INDEX_UUID).required(false);
        _argumentParser.addArgument("-a", "--" + KEY_ACTION).choices(CLEAR_INDEX_DELETION).setDefault(CLEAR_INDEX_DELETION);
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

        System.out.printf("\naction: %s\nsource file: %s\ntarget file: %s\n"
            + "index name: %s\nindex uuid: %s\n\n",
            action, sourceFile, targetFile, indexName, indexUUID);

        if (StringExtension.isBlank(targetFile))
            targetFile = sourceFile;

        StateMetaData<MetaData> clusterMetaData = StateMetaData.newClusterMetaData(sourceFile);
        System.out.printf("\nOld State:\n%s\n\n", clusterMetaData.toJson());
        MetaData metaData = clusterMetaData.getMetaData();
        MetaData.Builder builder = MetaData.builder(metaData);
        builder.removeCustom(IndexGraveyard.TYPE);
        IndexGraveyard indexGraveyard = (IndexGraveyard) metaData.getCustoms().get(IndexGraveyard.TYPE);
        if (indexGraveyard != null) {
            List<Tombstone> tombstones = indexGraveyard.getTombstones();
            if (!CollectionExtension.isEmpty(tombstones)) {
                tombstones = new ArrayList<>(tombstones);
                if (!StringExtension.isBlank(indexName) && !StringExtension.isBlank(indexUUID)) {
                    Index index = new Index(indexName, indexUUID);
                    tombstones.removeIf(t -> index.equals(t.getIndex()));
                } else if (StringExtension.isBlank(indexName) && StringExtension.isBlank(indexUUID)) {
                    tombstones.clear();
                } else if (StringExtension.isBlank(indexName)) {
                    tombstones.removeIf(t -> t.getIndex().getUUID().equals(indexUUID));
                } else {
                    tombstones.removeIf(t -> t.getIndex().getName().equals(indexName));
                }
                IndexGraveyard.Builder indexGraveyardBuilder = IndexGraveyard.builder();
                Class<IndexGraveyard.Builder> clazz = IndexGraveyard.Builder.class;
                Method method = clazz.getDeclaredMethod("addBuiltTombstones", List.class);
                method.setAccessible(true);
                method.invoke(indexGraveyardBuilder, tombstones);
                indexGraveyard = indexGraveyardBuilder.build();
                builder.putCustom(IndexGraveyard.TYPE, indexGraveyard);
                clusterMetaData = StateMetaData.newClusterMetaData(builder.build());
                clusterMetaData.saveTo(targetFile);
                clusterMetaData = StateMetaData.newClusterMetaData(targetFile);
            }
        }
        System.out.printf("\nNew State:\n%s\n\n", clusterMetaData.toJson());
    }

}
