<!-- v1.0 -->
<template>
  <component :is="tag" :class="classNames" class="tab-item">
    <slot />
  </component>
</template>

<script lang="ts" setup>
import { useDisabled } from '@core/composables/disabled.composable'
import { useUiStore } from '@core/stores/ui.store'
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    disabled?: boolean
    active?: boolean
    tag?: string
  }>(),
  { tag: 'span' }
)

const { isMobile } = storeToRefs(useUiStore())

const isDisabled = useDisabled(() => props.disabled)

const classNames = computed(() => {
  return [
    isMobile.value ? 'typo-caption-small' : 'typo-caption',
    {
      disabled: isDisabled.value,
      active: props.active,
    },
  ]
})
</script>

<style lang="postcss" scoped>
/* COLOR VARIANTS */
.tab-item {
  & {
    --color: var(--color-neutral-txt-primary);
    --border-color: transparent;
    --background-color: transparent;
  }

  &:is(:hover, .hover, :focus-visible) {
    --color: var(--color-neutral-txt-primary);
    --border-color: var(--color-brand-item-hover);
    --background-color: var(--color-brand-background-hover);
  }

  &:is(:active, .pressed) {
    --color: var(--color-neutral-txt-primary);
    --border-color: var(--color-brand-item-active);
    --background-color: var(--color-brand-background-active);
  }

  &:is(.active, .selected) {
    --color: var(--color-neutral-txt-primary);
    --border-color: var(--color-brand-item-base);
    --background-color: var(--color-brand-background-selected);
  }

  &:is(:disabled, .disabled) {
    --color: var(--color-neutral-txt-secondary);
    --border-color: transparent;
    --background-color: transparent;
  }
}

/* SIZE VARIANTS */
.tab-item {
  &.typo-caption-small {
    --spacing: 0.8rem;
  }

  &.typo-caption {
    --spacing: 1.6rem;
  }
}

/* IMPLEMENTATION */
.tab-item {
  display: flex;
  align-items: center;
  gap: var(--spacing);
  padding: var(--spacing);
  text-decoration: none;
  color: var(--color);
  background-color: var(--background-color);
  border-bottom: 0.2rem solid var(--border-color);
  cursor: pointer;

  &.disabled {
    pointer-events: none;
  }
}
</style>
