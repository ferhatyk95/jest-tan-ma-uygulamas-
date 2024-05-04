function jestTanima(kirmiziEsik, yesilEsik, maviEsik, numFrame)
    warning('off','vision:transition:usesOldCoordinates');

    if nargin < 1
        kirmiziEsik = 0.22; 
        yesilEsik = 0.14;
        maviEsik = 0.18;
        numFrame = 1000;
    end
    ekranBoyutu = get(0,'ScreenSize'); % Ekran boyutunu tanımla
    % Video ayarları
    [vidCihaz, vidBilgi] = setupVideoDevice();

    % Diğer ayarlar ve nesneler
    robot = java.awt.Robot;
    blobAnaliz = setupBlobAnalysis();
    sekilEkleme = setupShapeInserter();
    videoOynatici = setupVideoPlayer(vidBilgi);

    % İşlemler
    frameSayisi = 0;
    lSayisi = 0; rSayisi = 0; dSayisi = 0;
    iPozisyon = vidBilgi.MaxWidth/2;

    while (frameSayisi < numFrame)
       rgbKare = step(vidCihaz);
        rgbKare = flipdim(rgbKare,2);

        [merkezKirmizi, kutuKirmizi] = processColor(rgbKare(:,:,1), kirmiziEsik, blobAnaliz);
        [merkezYesil, kutuYesil] = processColor(rgbKare(:,:,2), yesilEsik, blobAnaliz);
        [~, kutuMavi] = processColor(rgbKare(:,:,3), maviEsik, blobAnaliz);

        performActions(robot, merkezKirmizi, kutuKirmizi, merkezYesil, kutuYesil, kutuMavi, iPozisyon, vidBilgi, ekranBoyutu);
        vidGiris = step(sekilEkleme, rgbKare, kutuKirmizi,single([1 0 0]));
        vidGiris = step(sekilEkleme, vidGiris, kutuYesil,single([0 1 0]));
        vidGiris = step(sekilEkleme, vidGiris, kutuMavi,single([0 0 1]));
        step(videoOynatici, vidGiris);

        frameSayisi = frameSayisi + 1;
    end

    release(videoOynatici);
    release(vidCihaz);
    clc;
end

function [vidCihaz, vidBilgi] = setupVideoDevice()
    kamera = imaqhwinfo;
    kameraAdi = char(kamera.InstalledAdaptors(end));
    kameraBilgi = imaqhwinfo(kameraAdi);
    kameraId = kameraBilgi.DeviceInfo.DeviceID(end);
    kameraFormat = char(kameraBilgi.DeviceInfo.SupportedFormats(end));

    vidCihaz = imaq.VideoDevice(kameraAdi, kameraId, kameraFormat, 'ReturnedColorSpace', 'RGB');
    vidBilgi = imaqhwinfo(vidCihaz);
end

function blobAnaliz = setupBlobAnalysis()
    blobAnaliz = vision.BlobAnalysis('AreaOutputPort', false, 'CentroidOutputPort', true, ...
                                     'BoundingBoxOutputPort', true, 'MaximumBlobArea', 3000, ...
                                     'MinimumBlobArea', 100, 'MaximumCount', 3);
end

function sekilEkleme = setupShapeInserter()
    sekilEkleme = vision.ShapeInserter('BorderColorSource', 'Input port', 'Fill', true, ...
                                       'FillColorSource', 'Input port', 'Opacity', 0.4);
end

function videoOynatici = setupVideoPlayer(vidBilgi)
    videoOynatici = vision.VideoPlayer('Name', 'Son Video', ...
                                       'Position', [100 100 vidBilgi.MaxWidth+20 vidBilgi.MaxHeight+30]);
end

function [merkez, kutu] = processColor(kanal, esik, blobAnaliz)
    if size(kanal, 3) == 3 % Eğer gelen görüntü RGB ise
        kanal = im2gray(kanal); % RGB'yi grileştir
    end
    
    diffKanal = imsubtract(kanal, esik); % Gerekli işlemleri yap
    binKanal = im2bw(diffKanal, esik);
    [merkez, kutu] = step(blobAnaliz, binKanal);
end



function performActions(robot, merkezKirmizi, kutuKirmizi, merkezYesil, kutuYesil, kutuMavi, iPozisyon)
    lSayisi = 0; rSayisi = 0; dSayisi = 0;
    eminOlay = 5;

    if length(kutuKirmizi(:,1)) == 1
        robot.mouseMove(1.5*merkezKirmizi(:,1)*ekranBoyutu(3)/vidBilgi.MaxWidth, 1.5*merkezKirmizi(:,2)*ekranBoyutu(4)/vidBilgi.MaxHeight);
    end

    if ~isempty(kutuMavi(:,1))
        if length(kutuMavi(:,1)) == 1
            lSayisi = lSayisi + 1;
            if lSayisi == eminOlay
                robot.mousePress(16);
                pause(0.1);
                robot.mouseRelease(16);
            end
        elseif length(kutuMavi(:,1)) == 2
            rSayisi = rSayisi + 1;
            if rSayisi == eminOlay
                robot.mousePress(4);
                pause(0.1);
                robot.mouseRelease(4);
            end
        elseif length(kutuMavi(:,1)) == 3
            dSayisi = dSayisi + 1;
            if dSayisi == eminOlay
                robot.mousePress(16);
                pause(0.1);
                robot.mouseRelease(16);
                pause(0.2);
                robot.mousePress(16);
                pause(0.1);
                robot.mouseRelease(16);
            end
        end
    else
        lSayisi = 0; rSayisi = 0; dSayisi = 0;
    end

    if ~isempty(kutuYesil(:,1))
        if (mean(merkezYesil(:,2)) - iPozisyon) < -2
            robot.mouseWheel(-1);
        elseif (mean(merkezYesil(:,2)) - iPozisyon) > 2
            robot.mouseWheel(1);
        end
        iPozisyon = mean(merkezYesil(:,2));
    end
end

