<script setup>
import { useForm } from '@inertiajs/vue3';
import LayoutPlatform from '@/Layouts/LayoutPlatform.vue';
import Button from '@/components/ui/Button.vue';
import { Lock, Loader2, Mail } from 'lucide-vue-next';

defineOptions({ layout: LayoutPlatform });

const props = defineProps({
    user: {
        type: Object,
        required: true,
    },
});

const emailForm = useForm({
    email: props.user.email,
});

const passwordForm = useForm({
    current_password: '',
    password: '',
    password_confirmation: '',
});

function submitEmail() {
    emailForm.put('/plataforma/conta/email', {
        preserveScroll: true,
    });
}

function submitPassword() {
    passwordForm.put('/plataforma/conta/senha', {
        preserveScroll: true,
        onSuccess: () => passwordForm.reset(),
    });
}
</script>

<template>
    <div class="mx-auto max-w-2xl space-y-8">
        <div>
            <h1 class="text-2xl font-bold tracking-tight text-zinc-900 dark:text-white">
                Minha conta
            </h1>
            <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
                Altere o e-mail e a senha do operador da plataforma.
            </p>
        </div>

        <div class="overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm dark:border-zinc-700 dark:bg-zinc-800/50">
            <div class="border-b border-zinc-200 px-6 py-4 dark:border-zinc-700 sm:px-8">
                <div class="flex items-center gap-2">
                    <span
                        class="flex h-9 w-9 items-center justify-center rounded-lg bg-[var(--color-primary)]/10 text-[var(--color-primary)]"
                    >
                        <Mail class="h-4 w-4" />
                    </span>
                    <h2 class="text-lg font-semibold text-zinc-900 dark:text-white">
                        E-mail de acesso
                    </h2>
                </div>
            </div>
            <form class="space-y-4 p-6 sm:p-8" @submit.prevent="submitEmail">
                <div>
                    <label for="platform-account-name" class="block text-sm font-medium text-zinc-700 dark:text-zinc-300">
                        Nome
                    </label>
                    <input
                        id="platform-account-name"
                        type="text"
                        :value="user.name"
                        disabled
                        class="mt-1.5 block w-full cursor-not-allowed rounded-xl border border-zinc-200 bg-zinc-50 px-4 py-2.5 text-zinc-600 dark:border-zinc-600 dark:bg-zinc-900/50 dark:text-zinc-400"
                    />
                </div>
                <div>
                    <label for="platform-account-email" class="block text-sm font-medium text-zinc-700 dark:text-zinc-300">
                        E-mail
                    </label>
                    <input
                        id="platform-account-email"
                        v-model="emailForm.email"
                        type="email"
                        required
                        autocomplete="email"
                        maxlength="255"
                        class="mt-1.5 block w-full rounded-xl border border-zinc-300 bg-white px-4 py-2.5 text-zinc-900 shadow-sm focus:border-[var(--color-primary)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]/20 dark:border-zinc-600 dark:bg-zinc-800 dark:text-white"
                    />
                    <p v-if="emailForm.errors.email" class="mt-1 text-sm text-red-600 dark:text-red-400">
                        {{ emailForm.errors.email }}
                    </p>
                </div>
                <Button type="submit" class="w-full sm:w-auto" :disabled="emailForm.processing">
                    <Loader2 v-if="emailForm.processing" class="mr-2 h-4 w-4 animate-spin" />
                    Salvar e-mail
                </Button>
            </form>
        </div>

        <div class="overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm dark:border-zinc-700 dark:bg-zinc-800/50">
            <div class="border-b border-zinc-200 px-6 py-4 dark:border-zinc-700 sm:px-8">
                <div class="flex items-center gap-2">
                    <span
                        class="flex h-9 w-9 items-center justify-center rounded-lg bg-[var(--color-primary)]/10 text-[var(--color-primary)]"
                    >
                        <Lock class="h-4 w-4" />
                    </span>
                    <h2 class="text-lg font-semibold text-zinc-900 dark:text-white">
                        Alterar senha
                    </h2>
                </div>
            </div>
            <form class="space-y-4 p-6 sm:p-8" @submit.prevent="submitPassword">
                <div>
                    <label for="platform-current-password" class="block text-sm font-medium text-zinc-700 dark:text-zinc-300">
                        Senha atual
                    </label>
                    <input
                        id="platform-current-password"
                        v-model="passwordForm.current_password"
                        type="password"
                        required
                        autocomplete="current-password"
                        class="mt-1.5 block w-full rounded-xl border border-zinc-300 bg-white px-4 py-2.5 text-zinc-900 shadow-sm focus:border-[var(--color-primary)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]/20 dark:border-zinc-600 dark:bg-zinc-800 dark:text-white"
                    />
                    <p v-if="passwordForm.errors.current_password" class="mt-1 text-sm text-red-600 dark:text-red-400">
                        {{ passwordForm.errors.current_password }}
                    </p>
                </div>
                <div>
                    <label for="platform-new-password" class="block text-sm font-medium text-zinc-700 dark:text-zinc-300">
                        Nova senha
                    </label>
                    <input
                        id="platform-new-password"
                        v-model="passwordForm.password"
                        type="password"
                        required
                        autocomplete="new-password"
                        class="mt-1.5 block w-full rounded-xl border border-zinc-300 bg-white px-4 py-2.5 text-zinc-900 shadow-sm focus:border-[var(--color-primary)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]/20 dark:border-zinc-600 dark:bg-zinc-800 dark:text-white"
                    />
                    <p v-if="passwordForm.errors.password" class="mt-1 text-sm text-red-600 dark:text-red-400">
                        {{ passwordForm.errors.password }}
                    </p>
                </div>
                <div>
                    <label for="platform-confirm-password" class="block text-sm font-medium text-zinc-700 dark:text-zinc-300">
                        Confirmar nova senha
                    </label>
                    <input
                        id="platform-confirm-password"
                        v-model="passwordForm.password_confirmation"
                        type="password"
                        required
                        autocomplete="new-password"
                        class="mt-1.5 block w-full rounded-xl border border-zinc-300 bg-white px-4 py-2.5 text-zinc-900 shadow-sm focus:border-[var(--color-primary)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]/20 dark:border-zinc-600 dark:bg-zinc-800 dark:text-white"
                    />
                </div>
                <Button type="submit" variant="outline" class="w-full sm:w-auto" :disabled="passwordForm.processing">
                    <Loader2 v-if="passwordForm.processing" class="mr-2 h-4 w-4 animate-spin" />
                    Alterar senha
                </Button>
            </form>
        </div>
    </div>
</template>
