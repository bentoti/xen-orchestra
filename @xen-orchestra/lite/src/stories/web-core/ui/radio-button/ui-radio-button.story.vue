<template>
  <ComponentStory
    v-slot="{ properties, settings }"
    :params="[
      prop('accent').required().enum('brand', 'warning', 'danger').preset('brand').widget(),
      prop('disabled').bool().widget(),
      slot().help('Meant to receive a label'),
      setting('defaultSlot').widget(text()).preset('Label'),
    ]"
  >
    <div>
      <UiRadioButton v-model="selectedRadio" value="1" v-bind="properties">{{ settings.defaultSlot }}</UiRadioButton>
    </div>
    <div>
      <UiRadioButton v-model="selectedRadio" value="2" v-bind="properties">
        {{ settings.defaultSlot }}
      </UiRadioButton>
    </div>
  </ComponentStory>
</template>

<script lang="ts" setup>
import ComponentStory from '@/components/component-story/ComponentStory.vue'
import { prop, setting, slot } from '@/libs/story/story-param'
import { text } from '@/libs/story/story-widget'
import UiRadioButton from '@core/components/ui/radio-button/UiRadioButton.vue'
import { ref } from 'vue'

const selectedRadio = ref('')
</script>
