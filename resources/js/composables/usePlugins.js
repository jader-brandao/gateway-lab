import { computed } from 'vue';
import { usePage } from '@inertiajs/vue3';

/**
 * Helpers para checar o estado dos plugins instalados.
 *
 * Usa `page.props.plugins` (array de { slug, name, version, is_enabled })
 * compartilhado por App\Http\Middleware\HandleInertiaRequests.
 */
export function usePlugins() {
    const page = usePage();

    const plugins = computed(() => {
        const list = page.props?.plugins;
        return Array.isArray(list) ? list : [];
    });

    function isPluginEnabled(slug) {
        if (!slug) return false;
        return plugins.value.some((p) => p?.slug === slug && !!p?.is_enabled);
    }

    return {
        plugins,
        isPluginEnabled,
    };
}
