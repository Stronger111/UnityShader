using System;

namespace UnityEditor.ShaderGraph
{
   public static class EnumInfo<T> where T : Enum
    {
        public static T[] values;

        static EnumInfo()
        {
            values = (T[])Enum.GetValues(typeof(T));
        }
    }
}
