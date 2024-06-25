classdef colorful < audioPlugin
    properties
        bandWidth = "1/12 octave";
        bands = [55 65.406 73.416 82.407 97.999 ...
                110 130.813 146.832 164.814 195.998 ...
                220 261.626 293.665 329.628 391.995 ...
                440 523.251 587.330 659.255 783.991 ...
                880 1046.502 1174.659 1318.510 1567.982 ...
                1760 2093.005 2349.318 2637.020 3135.963 ...
                3520 4186.009 4698.636 5274.041 6271.927 ...
                7040 8372.018 9397.272 10548.082 12543.854 ...
                14080 16744.036 18794.544];
        lowGaindB  = 0;   midGaindB   = 0;    highGaindB  = 0;
        EQU1_G1 = 0;  EQU1_G2 = 0;  EQU1_G3 = 0;
        power = true;
    end

    properties (Access = private)
        octFilts;
        objEQU1;
    end

    properties(Constant)
        PluginInterface = audioPluginInterface( ...
            audioPluginParameter('lowGaindB', ...
                'DisplayName','Low', 'Mapping',{'lin', -12, 12}, 'Layout',[2,1], 'DisplayNameLocation','above', 'Style','rotaryknob'), ...
            audioPluginParameter('midGaindB', ...
                'DisplayName','Mid', 'Mapping',{'lin', -12, 12}, 'Layout',[2,2], 'DisplayNameLocation','above', 'Style','rotaryknob'), ...
            audioPluginParameter('highGaindB', ...
                'DisplayName','High', 'Mapping',{'lin', -12, 12}, 'Layout',[2,3], 'DisplayNameLocation','above', 'Style','rotaryknob'), ...
            audioPluginParameter('power', ...
                'DisplayName','Power', 'Mapping',{'enum', 'OFF', 'ON'}, 'Layout',[2,4], 'DisplayNameLocation','None', 'Style','vtoggle'), ...
            audioPluginGridLayout( ...
                'RowHeight',[15,100,15], ...
                'ColumnWidth',[100,100,100,100]), ...
            'BackgroundColor',[222/255,222/255,222/255]);
        N = 8;
    end

    methods
        function plugin = colorful
            % 前処理のフィルタ設定を一回だけ行う
            sr = getSampleRate(plugin);
            plugin.octFilts = cell(1, length(plugin.bands));
            for i = 1:length(plugin.bands) 
                plugin.octFilts{i} = octaveFilter('FilterOrder',plugin.N, ...
                    'CenterFrequency',plugin.bands(i), 'Bandwidth',plugin.bandWidth, 'SampleRate', sr);
            end
            plugin.objEQU1 = multibandParametricEQ('NumEQBands',3,'EQOrder',4, ...
                'HasLowShelfFilter',0,'HasHighShelfFilter',0,'HasLowpassFilter',0,'HasHighpassFilter',0, ...
                'Frequencies',[200, 1000, 10000],'PeakGains',zeros(1,3),'QualityFactors',ones(1,3)*1.6,'SampleRate', sr);
        end

        function set.lowGaindB(plugin,val)
            plugin.objEQU1.PeakGains(1) = val; %#ok
        end
        function val = get.lowGaindB(plugin)
            val = plugin.objEQU1.PeakGains(1);
        end
        function set.midGaindB(plugin,val)
            plugin.objEQU1.PeakGains(2) = val; %#ok
        end
        function val = get.midGaindB(plugin)
            val = plugin.objEQU1.PeakGains(2);
        end
        function set.highGaindB(plugin,val)
            plugin.objEQU1.PeakGains(3) = val; %#ok
        end
        function val = get.highGaindB(plugin)
            val = plugin.objEQU1.PeakGains(3);
        end

        function out = process(plugin, in)
            if plugin.power
                result = zeros(size(in));
                % 並列処理を無効化し、シリアル処理に変更
                for i = 1:length(plugin.bands)
                    result = result + plugin.octFilts{i}(in); 
                end

                out = step(plugin.objEQU1, result);
            else
                out = in;
            end
        end

        function reset(plugin)
            sr = getSampleRate(plugin);
            for i = 1:length(plugin.bands)
                plugin.octFilts{i}.SampleRate = sr;
                reset(plugin.octFilts{i});
            end
        end
    end

end
