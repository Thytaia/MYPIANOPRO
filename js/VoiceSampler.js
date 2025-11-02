/**
 * js/VoiceSampler.js
 * Implementa uma única voz baseada em Amostragem (AudioBuffer).
 */
class VoiceSampler {
    constructor(audioContext) {
        this.context = audioContext;
        this.buffer = null; // AudioBuffer será injetado pelo PolyphonyManager
        this.output = this.context.createGain();
        this.output.gain.value = 0;
        this.source = null;
        this.isActive = false;
        this.isSustained = false;
    }

    setBuffer(buffer) {
        this.buffer = buffer;
    }

    start(frequency, velocity, destinationNode, envelopes) {
        if (!this.buffer) return;
        
        this.source = this.context.createBufferSource();
        this.source.buffer = this.buffer;
        this.source.loop = true; // Samples de Pad tipicamente usam loop
        
        // Simulação do Pitch (Nota MIDI 60 = C4)
        const C4_FREQ = 261.63; 
        this.source.playbackRate.setValueAtTime(frequency / C4_FREQ, this.context.currentTime); 
        
        this.source.connect(this.output);
        this.output.connect(destinationNode);
        
        this.startTime = this.context.currentTime;
        this.isActive = true;

        // Aplicação do ADSR (Attack lento do Fantasia Pad)
        const { attack } = envelopes; 
        
        this.output.gain.cancelScheduledValues(this.context.currentTime);
        this.output.gain.setValueAtTime(0, this.context.currentTime);
        // Attack Lento (Fantasia)
        this.output.gain.linearRampToValueAtTime(1.0 * velocity, this.context.currentTime + attack);
        
        this.source.start(this.context.currentTime);
    }

    stop(isSustainActive = false, envelopes) {
        this.isSustained = isSustainActive;
        const { release } = envelopes; 

        this.output.gain.cancelScheduledValues(this.context.currentTime);

        if (isSustainActive) {
            return;
        }

        // Release Lento (Fantasia)
        this.output.gain.setValueAtTime(this.output.gain.value, this.context.currentTime);
        this.output.gain.linearRampToValueAtTime(0, this.context.currentTime + release);

        // Para o buffer após o release
        try {
            this.source.stop(this.context.currentTime + release + 0.01); 
        } catch (e) {
            // Evita erro se o stop for chamado duas vezes
        }
        
        setTimeout(() => this.isActive = false, release * 1000 + 10);
    }
}