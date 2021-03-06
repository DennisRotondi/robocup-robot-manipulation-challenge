function ptCloudWorld = get_pcloud_from_photo
    %GET_PCLOUD_FROM_PHOTO Summary of this function goes here
    persistent pointCloudSub
    pointCloudSub = rossubscriber('/camera/depth/points');
    pointcloud = receive(pointCloudSub);

    tftree=rostf;
    camera_transf = getTransform(tftree,'world','camera_link');
    attemptn=0;
    
    while(size(camera_transf) == [0,1])
        pause(1)
        camera_transf = getTransform(tftree,'world','camera_link');
        attemptn=attemptn+1;
        if attemptn > 5
            ptCloudWorld = "fail";
            return
        end
    end
    camera_transl = camera_transf.Transform.Translation;
    camera_rotation = camera_transf.Transform.Rotation;
    camera_quaternions = [camera_rotation.W, camera_rotation.X,...
        camera_rotation.Y,camera_rotation.Z];
    camera_translations = [camera_transl.X,...
        camera_transl.Y,camera_transl.Z];
    xyz = readXYZ(pointcloud)
    xyzLess = double(rmmissing(xyz));
    ptCloud = pointCloud(xyzLess);
    
    rotm = quat2rotm(camera_quaternions);
    fixedRotation = eul2rotm([0 pi 0],"XYZ"); % fixed rotation between gazebo camera and urdf camera link
    rotm = rotm*fixedRotation' ;
    translVect = camera_translations;
    tform = rigid3d(rotm,[translVect(1),translVect(2),translVect(3)]);
    % Transform point cloud to world frame
    ptCloudWorld = pctransform(ptCloud,tform);
    indx = find(ptCloudWorld.Location(:,3) > -0.05);
    ptCloudWorld = select(ptCloudWorld,indx);
end

