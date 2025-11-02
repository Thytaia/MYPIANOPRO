/**
 * js/EffectModule.js
 * Gerencia os efeitos mestre (Reverb e Chorus) no Signal Chain.
 */
class EffectModule {
    constructor(audioContext) {
        this.context = audioContext;

        // Cria os nós de processamento
        this.input = this.context.createGain();
        this.output = this.context.createGain();

        // Módulos de Efeitos
        this.reverb = this.createReverb();
        this.chorus = this.createChorus();

        // Conexão dos Módulos: Input -> Chorus -> Reverb -> Output
        this.input.connect(this.chorus.input);
        this.chorus.output.connect(this.reverb.input);
        this.reverb.output.connect(this.output);
    }
    
    createReverb() {
        const convolver = this.context.createConvolver();
        const wetGain = this.context.createGain();
        wetGain.gain.value = 0.3; // Nível inicial de 30% Wet (Será controlado por Knobs)

        // Simulação do carregamento de um Impulse Response (IR)
        // Em um projeto real, 'fetch' carregaria um arquivo WAV IR de 'assets/samples/'
        const impulseResponse = this.context.createBuffer(2, this.context.sampleRate * 2, this.context.sampleRate);
        convolver.buffer = impulseResponse; // Buffer placeholder

        // Rota Dry (Input) e Rota Wet (Convolver)
        this.input.connect(convolver);
        convolver.connect(wetGain);
        
        // Retorna a estrutura de nó para o Signal Chain
        return { input: this.input, output: wetGain }; 
    }

    createChorus() {
        // Implementação simplificada do Chorus usando um Delay Modulado
        const delay = this.context.createDelay(0.1); // Delay máximo de 100ms
        delay.delayTime.value = 0.025; // Delay inicial de 25ms

        // Modulação do Delay (LFO)
        const lfo = this.context.createOscillator();
        lfo.type = 'sine';
        lfo.frequency.value = 0.5; // Taxa de 0.5 Hz
        const depth = this.context.createGain();
        depth.gain.value = 0.005; // Profundidade da modulação (5ms)
        
        lfo.connect(depth);
        depth.connect(delay.delayTime);
        lfo.start(0);

        // Conexão do sinal principal através do delay
        this.input.connect(delay);
        
        const chorusOutput = this.context.createGain();
        // Sinal Original + Sinal com Delay
        this.input.connect(chorusOutput); // Dry
        delay.connect(chorusOutput);    // Wet

        return { input: this.input, output: chorusOutput };
    }

    // Método para conectar ao próximo nó (Master Gain)
    connect(destinationNode) {
        this.output.connect(destinationNode);
    }
}