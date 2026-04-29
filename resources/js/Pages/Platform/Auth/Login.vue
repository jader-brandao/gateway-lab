<script setup>
import { ref, computed } from 'vue';
import { useForm, Link, usePage } from '@inertiajs/vue3';
import { Eye, EyeOff } from 'lucide-vue-next';
import Button from '@/components/ui/Button.vue';

const showPassword = ref(false);
const page = usePage();
const flashError = computed(() => page.props.flash?.error ?? null);

const branding = computed(() => page.props.public_branding ?? {});
const primary = computed(() => branding.value.theme_primary || '#8A2BE2');
const appName = computed(() => branding.value.app_name || 'gatewayLab');
const logoLight = computed(() => branding.value.app_logo || '/icons/logo.png');
const logoDark = computed(() => branding.value.app_logo_dark || logoLight.value);

const form = useForm({
    email: '',
    password: '',
    remember: false,
});

function submit() {
    form.post('/plataforma/login', {
        onFinish: () => form.reset('password'),
    });
}
</script>

<template>
    <div
        class="wl-root flex min-h-screen items-center justify-center bg-zinc-100 px-4 py-12 dark:bg-[#0D0D14]"
        :style="{
            backgroundImage: `radial-gradient(ellipse 80% 50% at 50% -20%, color-mix(in srgb, ${primary} 18%, transparent), transparent)`,
        }"
    >
        <div class="w-full max-w-md rounded-2xl border border-zinc-200/80 bg-white p-8 shadow-sm dark:border-white/10 dark:bg-[#1A1A24]">
            <div class="text-center">
                <img
                    :src="logoLight"
                    :alt="appName"
                    class="mx-auto mb-10 h-12 w-auto object-contain dark:hidden"
                />
                <img
                    :src="logoDark"
                    :alt="appName"
                    class="mx-auto mb-10 hidden h-12 w-auto object-contain dark:block"
                />
                <h1 class="text-2xl font-bold text-zinc-900 dark:text-white">Plataforma</h1>
                <p class="mt-1 text-sm text-zinc-600 dark:text-zinc-400">Acesso do operador do gateway</p>
            </div>

            <p
                v-if="flashError"
                class="mt-4 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800 dark:border-amber-800 dark:bg-amber-950/40 dark:text-amber-200"
            >
                {{ flashError }}
            </p>
            <form class="mt-8 space-y-5" @submit.prevent="submit">
                <div>
                    <label for="email" class="block text-sm font-medium text-zinc-700 dark:text-zinc-300">E-mail</label>
                    <input
                        id="email"
                        v-model="form.email"
                        type="email"
                        autocomplete="email"
                        required
                        class="wl-input mt-1.5 block w-full rounded-xl border border-zinc-300 bg-white px-4 py-3 text-zinc-900 placeholder-zinc-500 shadow-sm transition dark:border-zinc-600 dark:bg-zinc-900 dark:text-white dark:placeholder-zinc-500"
                        placeholder="seu@email.com"
                    />
                    <p v-if="form.errors.email" class="mt-1.5 text-sm text-red-600 dark:text-red-400">{{ form.errors.email }}</p>
                </div>
                <div>
                    <label for="password" class="block text-sm font-medium text-zinc-700 dark:text-zinc-300">Senha</label>
                    <div class="relative mt-1.5">
                        <input
                            id="password"
                            v-model="form.password"
                            :type="showPassword ? 'text' : 'password'"
                            autocomplete="current-password"
                            required
                            class="wl-input block w-full rounded-xl border border-zinc-300 bg-white py-3 pl-4 pr-12 text-zinc-900 placeholder-zinc-500 shadow-sm transition dark:border-zinc-600 dark:bg-zinc-900 dark:text-white dark:placeholder-zinc-500"
                            placeholder="••••••••"
                        />
                        <button
                            type="button"
                            class="wl-focus-ring absolute right-3 top-1/2 -translate-y-1/2 rounded p-1.5 text-zinc-500 transition hover:text-zinc-700 focus:outline-none dark:text-zinc-400 dark:hover:text-zinc-200"
                            :aria-label="showPassword ? 'Ocultar senha' : 'Mostrar senha'"
                            @click="showPassword = !showPassword"
                        >
                            <Eye v-if="showPassword" class="h-5 w-5" />
                            <EyeOff v-else class="h-5 w-5" />
                        </button>
                    </div>
                    <p v-if="form.errors.password" class="mt-1.5 text-sm text-red-600 dark:text-red-400">{{ form.errors.password }}</p>
                </div>
                <div class="flex items-center gap-3">
                    <input
                        id="remember"
                        v-model="form.remember"
                        type="checkbox"
                        class="wl-checkbox h-4 w-4 rounded border-zinc-300 dark:border-zinc-600"
                    />
                    <label for="remember" class="text-sm text-zinc-700 dark:text-zinc-300">Lembrar de mim</label>
                </div>
                <Button
                    type="submit"
                    class="wl-submit w-full hover:!opacity-90"
                    :disabled="form.processing"
                >
                    {{ form.processing ? 'Entrando…' : 'Entrar' }}
                </Button>
            </form>

            <p class="mt-6 text-center text-sm text-zinc-600 dark:text-zinc-400">
                É vendedor ou equipe?
                <Link href="/login" class="wl-link font-medium hover:underline">Acesse o painel do infoprodutor</Link>
            </p>
            <p class="mt-3 text-center">
                <Link href="/esqueci-senha" class="wl-link text-sm font-medium hover:underline focus:outline-none focus:ring-2 focus:ring-offset-2 dark:focus:ring-offset-zinc-900 rounded">
                    Recuperar senha
                </Link>
            </p>
        </div>
    </div>
</template>

<style scoped>
.wl-root {
    --wl-primary: v-bind(primary);
}
.wl-input:hover {
    border-color: color-mix(in srgb, var(--wl-primary) 45%, var(--tw-border-color, #d4d4d8));
}
.wl-input:focus {
    border-color: var(--wl-primary);
    outline: none;
    box-shadow: 0 0 0 2px color-mix(in srgb, var(--wl-primary) 35%, transparent);
}
.wl-focus-ring:focus {
    box-shadow: 0 0 0 2px color-mix(in srgb, var(--wl-primary) 35%, transparent);
}
.wl-checkbox {
    accent-color: var(--wl-primary);
}
.wl-submit {
    background-color: var(--wl-primary) !important;
    color: #ffffff !important;
}
.wl-link {
    color: var(--wl-primary);
}
.wl-link:focus {
    --tw-ring-color: color-mix(in srgb, var(--wl-primary) 35%, transparent);
}
</style>
