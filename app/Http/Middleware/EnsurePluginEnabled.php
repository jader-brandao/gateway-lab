<?php

namespace App\Http\Middleware;

use App\Plugins\PluginRegistry;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsurePluginEnabled
{
    /**
     * Aborta com 404 quando o plugin (slug) não está instalado/ativado.
     * Uso: ->middleware('plugin.enabled:afiliados')
     */
    public function handle(Request $request, Closure $next, string $slug): Response
    {
        if (! PluginRegistry::isEnabled($slug)) {
            abort(404);
        }

        return $next($request);
    }
}
