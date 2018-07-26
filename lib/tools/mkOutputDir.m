function outputFolder = mkOutputDir(Params,saving)
if saving.Data_on  || saving.MapsVideo_on || saving.MapsImage_on || saving.StatVideo_on || saving.StatImage_on
  outputFolder.Main = Params.OutputDir;
  mkdir(outputFolder.Main)
  if saving.Data_on
    outputFolder.Data = [outputFolder.Main,'Data/'];
    mkdir(outputFolder.Data)
  end
  if saving.MapsVideo_on
    outputFolder.MapsVideo = [outputFolder.Main,'MapsVideo/'];
    mkdir(outputFolder.MapsVideo)
  end
  if saving.MapsImage_on
    outputFolder.MapsImage = [outputFolder.Main,'MapsImage/'];
    mkdir(outputFolder.MapsImage)
  end
  if saving.StatVideo_on
    outputFolder.StatVideo = [outputFolder.Main,'StatVideo/'];
    mkdir(outputFolder.StatVideo)
  end
  if saving.StatImage_on
    outputFolder.StatImage = [outputFolder.Main,'StatImage/'];
    mkdir(outputFolder.StatImage)
  end
else
  outputFolder = [];
end
end