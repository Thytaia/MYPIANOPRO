/**
 * js/PolyphonyManager.js
 * Lógica Central de Gerenciamento de 256 Vozes e Voice-Stealing.
 */

const MIDI_TO_FREQ = (midi) => 440 * Math.pow(2, (midi - 69) / 12);
const MAX_VOICES = 256;

class PolyphonyManager {
    constructor(maxVoices, audioContext, destinationNode) {
        this.context = audioContext;
        this.destinationNode = destinationNode; // O Input do EffectModule
        this.maxVoices = maxVoices; 
        this.activeVoices = []; 
        this.isSustainPedalOn = false;
        this.pressedNotes = new Map(); // Rastreia as notas ativas no teclado (para evitar duplicidade)

        // Pools de vozes (pré-alocadas para performance)
        this.voicePoolFM = new Array(this.maxVoices / 2).fill().map(() => new VoiceFM(this.context));
        this.voicePoolSampler = new Array(this.maxVoices / 2).fill().map(() => new VoiceSampler(this.context));

        this.polifoniaDisplay = document.getElementById('polifonia-display');
    }

    // Simula o carregamento de samples (chamado pelo AudioEngine)
    async loadSamples() {
        // Simulação de criação de um buffer para o Fantasia Pad
        const buffer = this.context.createBuffer(2, this.context.sampleRate * 4, this.context.sampleRate);
        this.voicePoolSampler.forEach(voice => voice.setBuffer(buffer));
        
        // Simulação de carregamento de IR para o Reverb (após o AudioEngine estar pronto)
        const irBuffer = this.context.createBuffer(2, this.context.sampleRate * 1.5, this.context.sampleRate);
        // Assumindo que o AudioEngine está no escopo, configure o ConvolverNode:
        // audioEngine.effectModule.reverb.convolver.buffer = irBuffer;
    }
    
    // Rota central de alocação de voz
    getFreeVoice(type) {
        const pool = (type === 'FM') ? this.voicePoolFM : this.voicePoolSampler;
        
        // 1. Tentar pegar uma voz inativa
        let freeVoice = pool.find(voice => !voice.isActive); 
        
        // 2. Aplicar Voice-Stealing se o pool de ativos estiver cheio
        if (!freeVoice && this.activeVoices.length >= this.maxVoices) {
            freeVoice = this.voiceStealing();
        }

        if (freeVoice) {
            // Remove a voz "roubada" se for o caso
            this.activeVoices = this.activeVoices.filter(v => v !== freeVoice);
            this.activeVoices.push(freeVoice);
            return freeVoice;
        }
        return null;
    }

    // Lógica de corte de voz (Voice-Stealing)
    voiceStealing() {
        // Prioridade: A voz mais antiga (menor startTime) que NÃO está sob sustain
        const victim = this.activeVoices
            .sort((a, b) => a.startTime - b.startTime)
            .find(voice => !voice.isSustained); 
            
        if (victim) {
            // Interrompe o som da vítima imediatamente (liberando-a)
            victim.stop(false); 
            return victim;
        }
        // Se todas estiverem sustentadas (caso extremo), corta a mais antiga (0)
        this.activeVoices[0].stop(false); 
        return this.activeVoices[0];
    }
    
    // Chamado para tocar uma nota
    playNote(midiNote, presetID) {
        const preset = PresetBank[presetID];
        if (!preset) return;
        
        const noteIdentifier = `${midiNote}-${presetID}`;
        
        // Adiciona um array para rastrear as vozes de cada nota/layer
        if (!this.pressedNotes.has(noteIdentifier)) {
            this.pressedNotes.set(noteIdentifier, []);
        }

        const noteVoices = this.pressedNotes.get(noteIdentifier);

        // Instancia uma voz para cada Layer (simulação do consumo de polifonia)
        for (let i = 0; i < preset.layerCount; i++) {
            const voice = this.getFreeVoice(preset.type);
            
            if (voice) {
                const freq = MIDI_TO_FREQ(midiNote);
                
                if (preset.type === "FM") {
                    voice.start(freq, 1.0, this.destinationNode);
                } else if (preset.type === "SAMPLE") {
                    voice.start(freq, 1.0, this.destinationNode, preset.envelopes);
                }
                noteVoices.push(voice);
            }
        }
        this.updateDisplay();
    }
    
    // Chamado para liberar uma nota
    stopNote(midiNote, presetID) {
        const noteIdentifier = `${midiNote}-${presetID}`;

        if (this.pressedNotes.has(noteIdentifier)) {
            const noteVoices = this.pressedNotes.get(noteIdentifier);
            const preset = PresetBank[presetID];

            // Para todas as vozes alocadas para esta nota
            noteVoices.forEach(voice => {
                if (preset.type === "FM") {
                    voice.stop(this.isSustainPedalOn);
                } else if (preset.type === "SAMPLE") {
                    voice.stop(this.isSustainPedalOn, preset.envelopes);
                }
            });
            
            // Remove do rastreamento se o pedal de sustain não estiver ativo
            if (!this.isSustainPedalOn) {
                this.pressedNotes.delete(noteIdentifier);
            }
        }
        this.updateDisplay();
    }

    updateDisplay() {
        // Filtra vozes que não estão mais tocando ou em sustain
        this.activeVoices = this.activeVoices.filter(v => v.isActive || v.isSustained); 
        const count = this.activeVoices.length;
        this.polifoniaDisplay.innerText = `POLIFONIA: ${count}/${this.maxVoices} VOZES`;
    }
    
    // Método para controle do pedal de Sustain (Futuro mapeamento no PC)
    setSustain(isOn) {
        this.isSustainPedalOn = isOn;
        // Lógica para liberar as notas em 'release' quando o sustain é desligado
    }
}