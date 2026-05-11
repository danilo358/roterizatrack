<script setup lang="ts">
import { AlertCircle, X } from 'lucide-vue-next';

defineProps<{
  show: boolean;
  title: string;
  message: string;
}>();

defineEmits(['confirm', 'cancel']);
</script>

<template>
  <Transition name="modal">
    <div v-if="show" class="modal-overlay" @click="$emit('cancel')">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <div class="modal-icon">
            <AlertCircle :size="24" />
          </div>
          <button class="close-btn" @click="$emit('cancel')">
            <X :size="20" />
          </button>
        </div>
        
        <div class="modal-body">
          <h3>{{ title }}</h3>
          <p>{{ message }}</p>
        </div>
        
        <div class="modal-footer">
          <button class="btn-cancel" @click="$emit('cancel')">Cancelar</button>
          <button class="btn-confirm" @click="$emit('confirm')">Confirmar</button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}

.modal-content {
  background: var(--surface);
  width: 100%;
  max-width: 400px;
  border-radius: 24px;
  border: 1px solid var(--border);
  box-shadow: var(--shadow);
  overflow: hidden;
  padding: 1.5rem;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 1rem;
}

.modal-icon {
  width: 48px;
  height: 48px;
  background: rgba(59, 130, 246, 0.1);
  color: var(--primary);
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-btn {
  background: none;
  border: none;
  color: var(--text-muted);
  cursor: pointer;
  padding: 0.5rem;
  border-radius: 50%;
  transition: all var(--transition);
}

.close-btn:hover {
  background: var(--surface-light);
  color: var(--text);
}

.modal-body h3 {
  font-size: 1.25rem;
  font-weight: 700;
  margin-bottom: 0.5rem;
}

.modal-body p {
  color: var(--text-muted);
  font-size: 0.95rem;
  line-height: 1.5;
  margin-bottom: 2rem;
}

.modal-footer {
  display: flex;
  gap: 1rem;
}

.modal-footer button {
  flex: 1;
  padding: 0.75rem;
  border-radius: 12px;
  font-weight: 700;
  cursor: pointer;
  transition: all var(--transition);
}

.btn-cancel {
  background: transparent;
  border: 1px solid var(--border);
  color: var(--text);
}

.btn-cancel:hover {
  background: var(--surface-light);
}

.btn-confirm {
  background: var(--primary);
  border: none;
  color: white;
}

.btn-confirm:hover {
  background: var(--primary-hover);
  transform: translateY(-1px);
}

/* Transitions */
.modal-enter-active, .modal-leave-active {
  transition: opacity 0.3s ease;
}

.modal-enter-from, .modal-leave-to {
  opacity: 0;
}
</style>
