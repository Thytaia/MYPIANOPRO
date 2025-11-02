/**
 * js/VoiceFM.js
 * Implementa uma única voz baseada em Síntese por Modulação de Frequência (FM).
 */
class VoiceFM {
    constructor(audioContext) {
        this.context = audioContext;
        this.operators = []; // Array para os osciladores
        this.output = this.context.createGain();
        this.output.gain.value = 0; // Inicia silenciosa
        this.isActive = false;
        this.isSustained = false;

        // Criar os 3 operadores (Osciladores e Gains) para o protótipo
        for (let i = 0; i < 3; i++) {
            const op = this.context.createOscillator();
            const gain = this.context.createGain();
            op.type = 'sine';
            op.connect(gain);
            this.operators.push({ op, gain, started: false });
        }
    }

    // Configura a voz e inicia a nota
    start(frequency, velocity, destinationNode) {
        this.startTime = this.context.currentTime;
        this.isActive = true;
        
        // Configuração do preset DX7 E. Piano 1 (Algoritmo 6)
        // Op 0 (Modulador) -> Op 2 (Carrier)
        this.operators[0].gain.connect(this.operators[2].op.frequency);
        // Op 2 (Carrier) -> Output
        this.operators[2].gain.connect(this.output);
        this.output.connect(destinationNode);

        // Define a frequência base e inicia os operadores
        this.operators.forEach((op, index) => {
            // Frequência: base * ratio (simplificado)
            op.op.frequency.setValueAtTime(frequency * (index === 1 ? 1.41 : 1.0), this.context.currentTime); 
            
            if (!op.started) {
                op.op.start(0);
                op.started = true;
            }
        });
        
        // Aplicação simplificada do ADSR (Attack e Decay rápidos do E. Piano)
        const attackTime = 0.01;
        const decayTime = 0.3;
        const sustainLevel = 0.7; 
        
        this.output.gain.cancelScheduledValues(this.context.currentTime);
        this.output.gain.setValueAtTime(0, this.context.currentTime);
        // Attack
        this.output.gain.linearRampToValueAtTime(1.0 * velocity, this.context.currentTime + attackTime);
        // Decay/Sustain
        this.output.gain.linearRampToValueAtTime(sustainLevel * velocity, this.context.currentTime + attackTime + decayTime);
    }

    // Libera a nota
    stop(isSustainActive = false) {
        this.isSustained = isSustainActive;
        const releaseTime = 0.5;

        this.output.gain.cancelScheduledValues(this.context.currentTime);
        
        if (isSustainActive) {
            // Mantém o nível de sustain ativo, o PolyphonyManager gerenciará o corte
            return; 
        }

        // Release (se o sustain não estiver ativo)
        this.output.gain.setValueAtTime(this.output.gain.value, this.context.currentTime);
        this.output.gain.linearRampToValueAtTime(0, this.context.currentTime + releaseTime);

        // Marca a voz como inativa após o release
        this.output.gain.setValueAtTime(0, this.context.currentTime + releaseTime + 0.01);
        setTimeout(() => this.isActive = false, releaseTime * 1000 + 10); 
    }
}