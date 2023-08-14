#!/bin/bash

# 检查参数是否为文件
if [ -f "$1" ]; then
  # 使用`readlink`命令获取文件路径的绝对路径
  URDF_ABSOLUTE_PATH=$(readlink -f "$1")
  echo "传递进来的文件路径的绝对路径是：$URDF_ABSOLUTE_PATH"
else
  echo "传递进来的参数不是一个文件"
fi

ros2 pkg create robot_description --build-type ament_python
cd robot_description 
if [ ! -d "urdf" ]; then
mkdir urdf
fi
cd urdf
cp -f $URDF_ABSOLUTE_PATH robot_base.urdf

# echo  -e $MY_CONTENT > robot_base.urdf

# 建立launch文件
cd ..
if [ ! -d "launch" ]; then
mkdir launch
fi
cd launch
touch -a display_rviz2.launch.py

echo -e \
"import os
from launch import LaunchDescription
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare


def generate_launch_description():
    package_name = 'robot_description'
    urdf_name = \"robot_base.urdf\"

    ld = LaunchDescription()
    pkg_share = FindPackageShare(package=package_name).find(package_name) 
    urdf_model_path = os.path.join(pkg_share, f'urdf/{urdf_name}')

    robot_state_publisher_node = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        arguments=[urdf_model_path]
        )

    joint_state_publisher_node = Node(
        package='joint_state_publisher_gui',
        executable='joint_state_publisher_gui',
        name='joint_state_publisher_gui',
        arguments=[urdf_model_path]
        )

    rviz2_node = Node(
        package='rviz2',
        executable='rviz2',
        name='rviz2',
        output='screen',
        )

    ld.add_action(robot_state_publisher_node)
    ld.add_action(joint_state_publisher_node)
    ld.add_action(rviz2_node)

    return ld
" > display_rviz2.launch.py

# 修改setup.py
cd ../
echo -e \
"from setuptools import setup
from glob import glob
import os

package_name = 'robot_description'

setup(
    name=package_name,
    version='0.0.0',
    packages=[package_name],
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
        (os.path.join('share', package_name, 'launch'), glob('launch/*.launch.py')),
        (os.path.join('share', package_name, 'urdf'), glob('urdf/**')),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='root',
    maintainer_email='root@todo.todo',
    description='TODO: Package description',
    license='TODO: License declaration',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
        ],
    },
)
" > setup.py

colcon build

source install/setup.bash
ros2 launch robot_description display_rviz2.launch.py