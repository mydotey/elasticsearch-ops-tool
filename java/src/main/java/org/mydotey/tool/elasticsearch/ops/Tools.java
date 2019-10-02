package org.mydotey.tool.elasticsearch.ops;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.HashMap;

/**
 * @author koqizhao
 *
 * Dec 10, 2018
 */
public class Tools {

    private static HashMap<Class<?>, String> _tools = new HashMap<>();

    static {
        _tools.put(ManifestStateFileEditor.class, "Edit the Manifest state file.");
        _tools.put(ClusterStateFileEditor.class, "Edit the Cluster state file.");
    }

    public static void main(String[] args) throws Exception {
        if (args.length == 0) {
            System.out.println("elasticsearch ops tool list\n");
            _tools.forEach((t, d) -> {
                System.out.printf("class: %s\ndetails:\n%s\n\n", t.getName(), d);
            });

            return;
        }

        Class<?> clazz = Class.forName(args[0]);
        if (!_tools.containsKey(clazz)) {
            System.err.println("unknow tool: " + clazz);
            return;
        }

        Method mainMethod = clazz.getMethod("main", String[].class);
        try {
            mainMethod.invoke(null, new Object[] { Arrays.copyOfRange(args, 1, args.length) });
        } catch (InvocationTargetException e) {
            e.getCause().printStackTrace();
        }
    }

}
